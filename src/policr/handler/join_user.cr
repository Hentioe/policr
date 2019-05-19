module Policr
  class JoinUserHandler < Handler
    alias VerifyStatus = Cache::VerifyStatus

    def match(msg)
      all_pass? [
        DB.enable_examine?(msg.chat.id),
        msg.new_chat_members,
      ]
    end

    def handle(msg)
      if (members = msg.new_chat_members) && (halal_message_handler = bot.handlers[:halal_message]?) && halal_message_handler.is_a?(HalalMessageHandler)
        members.select { |m| m.is_bot == false }.each do |member|
          # 关联并缓存入群消息
          Cache.associate_join_msg(member.id, msg.chat.id, msg.message_id)
          name = bot.get_fullname(member)
          halal_message_handler.is_halal(name) ? halal_message_handler.kick_halal_with_receipt(msg, member) : torture_action(msg, member)
        end
      end
    end

    def add_banned_menu(user_id, username, is_halal = false)
      markup = Markup.new
      markup << Button.new(text: t("baned_menu.unban"), callback_data: "BanedMenu:#{user_id}:#{username}:unban")
      markup << Button.new(text: t("baned_menu.whitelist"), callback_data: "BanedMenu:#{user_id}:#{username}:whitelist") if is_halal
      markup
    end

    def torture_action(msg, member)
      Cache.verify_init(member.id)
      default =
        {
          1,
          t("questions.title"),
          [
            t("questions.answer_1"),
            t("questions.answer_2"),
          ],
        }
      custom = DB.custom(msg.chat.id)

      _, title, answers = custom ? custom : default

      # 禁言用户
      bot.restrict_chat_member(msg.chat.id, member.id, can_send_messages: false)

      torture_sec = DB.get_torture_sec(msg.chat.id, DEFAULT_TORTURE_SEC)
      name = bot.get_fullname(member)
      bot.log "Start to torture '#{name}'"
      question = t("torture.start", {torture_sec: torture_sec, title: title})
      reply_id = msg.message_id
      member_id = member.id.to_s
      member_username = member.username

      btn = ->(text : String, chooese_id : Int32) {
        Button.new(text: text, callback_data: "Torture:#{member_id}:#{member_username}:#{chooese_id}")
      }
      markup = Markup.new
      answers.each_with_index { |answer, i| markup << [btn.call(answer, i + 1)] }
      pass_text = t("admin_ope_menu.pass")
      ban_text = t("admin_ope_menu.ban")
      markup << [btn.call(pass_text, 0), btn.call(ban_text, -1)]
      sended_msg = bot.send_message(msg.chat.id, question, reply_to_message_id: reply_id, reply_markup: markup)

      ban_task = ->(message_id : Int32) {
        if Cache.verify?(member.id) == VerifyStatus::Init
          bot.log "User '#{name}' torture time expired and has been banned"
          Cache.verify_slowed(member.id)
          unverified_with_receipt(msg.chat.id, message_id, member.id, member.username)
        end
      }

      ban_timer = ->(message_id : Int32) { Schedule.after(torture_sec.seconds) { ban_task.call(message_id) } }
      if sended_msg && (message_id = sended_msg.message_id)
        ban_timer.call(message_id)
      end
    end

    def unverified_with_receipt(chat_id, message_id, user_id, username, admin = false)
      Cache.verify_status_clear user_id
      bot.log "Username '#{username}' has not been verified and has been banned"
      begin
        bot.kick_chat_member(chat_id, user_id)
      rescue ex : TelegramBot::APIException
        text = t "verify_result.error"
        bot.edit_message_text(chat_id: chat_id, message_id: message_id,
          text: text)
      else
        text = t "verify_result.failure"
        text = t("verify_result.admin_ban") if admin
        bot.edit_message_text(chat_id: chat_id, message_id: message_id,
          text: text, reply_markup: add_banned_menu(user_id, username))
      end
    end
  end
end
