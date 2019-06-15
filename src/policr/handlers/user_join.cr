module Policr
  class UserJoinHandler < Handler
    alias VerifyStatus = Cache::VerifyStatus

    def match(msg)
      all_pass? [
        DB.enable_examine?(msg.chat.id),
        msg.new_chat_members,
      ]
    end

    def handle(msg)
      chat_id = msg.chat.id

      if members = msg.new_chat_members
        members.select { |m| m.is_bot == false }.each do |member|
          # 管理员拉入，放行
          if (user = msg.from) && (user.id != member.id) && bot.is_admin?(msg.chat.id, user.id)
            if (sended_msg = bot.reply(msg, t("add_from_admin"))) && (message_id = sended_msg.message_id)
              Schedule.after(5.seconds) { bot.delete_message(chat_id, message_id) } unless DB.record_mode?(chat_id)
            end
            return
          end
          # 关联并缓存入群消息
          Cache.associate_join_msg(member.id, msg.chat.id, msg.message_id)
          # 判断清真
          name = bot.display_name(member)

          midcall HalalMessageHandler do
            handler.is_halal(name) ? handler.kick_halal_with_receipt(msg, member) : start_torture(msg, member)
          end
        end
      end
    end

    def add_banned_menu(user_id, username, is_halal = false)
      markup = Markup.new
      markup << Button.new(text: t("baned_menu.unban"), callback_data: "BanedMenu:#{user_id}:#{username}:unban")
      markup << Button.new(text: t("baned_menu.whitelist"), callback_data: "BanedMenu:#{user_id}:#{username}:whitelist") if is_halal
      markup
    end

    AFTER_EVENT_SEC = 60 * 15

    def start_torture(msg, member)
      if (Time.utc.to_unix - msg.date) > AFTER_EVENT_SEC
        # 事后审核不立即验证，采取人工处理
        # 禁言用户/异步调用
        spawn bot.restrict_chat_member(msg.chat.id, member.id, can_send_messages: false)
        markup = Markup.new
        btn = ->(text : String, item : String) {
          Button.new(text: text, callback_data: "AfterEvent:#{member.id}:#{member.username}:#{item}:#{msg.message_id}")
        }

        markup << [btn.call(t("after_event.torture"), "torture")]
        markup << [btn.call(t("after_event.unban"), "unban"), btn.call(t("after_event.kick"), "kick")]

        bot.send_message(msg.chat.id, t("after_event.tip"), reply_to_message_id: msg.message_id, disable_web_page_preview: true, reply_markup: markup, parse_mode: "markdown")
      else
        chat_id = msg.chat.id
        msg_id = msg.message_id
        member_id = member.id
        username = member.username
        promptly_torture(chat_id, msg_id, member_id, username)
      end
    end

    def promptly_torture(chat_id, msg_id, member_id, username, re = false)
      Cache.verify_init(member_id)

      params = {chat_id: chat_id, msg_id: msg_id}

      send_image = false
      catpcha_data =
        if DB.custom chat_id
          # 自定义验证
          CustomCaptcha.new(**params).make
        elsif DB.dynamic? chat_id
          # 动态验证
          DynamicCaptcha.new(**params).make
        elsif Cache.get_images.size >= 3 && DB.enabled_image?(chat_id)
          send_image = true
          # 图片验证
          ImageCaptcha.new(**params).make
        else
          # 默认验证
          DefaultCaptcha.new(**params).make
        end

      _, title, answers = catpcha_data

      image =
        if send_image
          answers.delete_at (answers.size - 1)
        end

      # 禁言用户/异步调用
      spawn bot.restrict_chat_member(chat_id, member_id, can_send_messages: false)

      torture_sec = DB.get_torture_sec(chat_id) || DEFAULT_TORTURE_SEC
      question =
        if send_image
          if torture_sec > 0
            hint = t("torture.caption", {torture_sec: torture_sec, title: title, user_id: member_id})
          else
            t("torture.caption_no_time", {user_id: member_id})
          end
        else
          if torture_sec > 0
            hint = t("torture.hint", {user_id: member_id, torture_sec: torture_sec, title: title})
          else
            t("torture.no_time_reply", {user_id: member_id, title: title})
          end
        end
      question = (t("torture.re") + question) if re
      reply_id = msg_id

      btn = ->(text : String, chooese_id : Int32) {
        Button.new(text: text, callback_data: "Torture:#{member_id}:#{username}:#{chooese_id}:#{send_image ? 1 : 0}")
      }
      markup = Markup.new
      answer_list = answers.map_with_index { |answer, i| [btn.call(answer, i + 1)] }
      answer_list.shuffle.each { |answer_btn| markup << answer_btn } # 乱序答案列表
      pass_text = t("admin_ope_menu.pass")
      ban_text = t("admin_ope_menu.ban")
      markup << [btn.call(pass_text, 0), btn.call(ban_text, -1)]
      sended_msg =
        if img = image
          bot.send_photo(chat_id, File.new(img), caption: question, reply_to_message_id: reply_id, reply_markup: markup, parse_mode: "markdown")
        else
          bot.send_message(chat_id, question, reply_to_message_id: reply_id, disable_web_page_preview: true, reply_markup: markup, parse_mode: "markdown")
        end
      ban_task = ->(message_id : Int32) {
        if Cache.verify?(member_id) == VerifyStatus::Init
          bot.log "User '#{username}' torture time expired and has been banned"
          Cache.verify_slowed(member_id)
          failed(chat_id, message_id, member_id, username, timeout: true, photo: send_image, reply_id: msg_id)
        end
      }

      ban_timer = ->(message_id : Int32) { Schedule.after(torture_sec.seconds) { ban_task.call(message_id) } }
      if sended_msg && (message_id = sended_msg.message_id)
        # 存在验证时间，定时任务调用
        ban_timer.call(message_id) if torture_sec > 0
      end
    end

    def failed(chat_id, message_id, user_id, username, admin = false, timeout = false, photo = false, reply_id : Int32? = nil)
      Cache.verify_status_clear user_id
      bot.log "Username '#{username}' has not been verified and has been banned"
      begin
        bot.kick_chat_member(chat_id, user_id)
      rescue ex : TelegramBot::APIException
        text = t "captcha_result.error", {user_id: user_id}
        if photo
          spawn bot.delete_message chat_id, message_id
          bot.send_message(chat_id: chat_id, text: text, reply_to_message_id: reply_id, parse_mode: "markdown")
        else
          bot.edit_message_text(chat_id: chat_id, message_id: message_id,
            text: text, parse_mode: "markdown")
        end
      else
        text =
          unless admin
            timeout ? t("captcha_result.timeout", {user_id: user_id}) : t("captcha_result.wrong", {user_id: user_id})
          else
            t("captcha_result.admin_ban", {user_id: user_id})
          end

        if photo
          spawn bot.delete_message chat_id, message_id
          bot.send_message(chat_id: chat_id, text: text, reply_to_message_id: reply_id, disable_web_page_preview: true, reply_markup: add_banned_menu(user_id, username), parse_mode: "markdown")
        else
          bot.edit_message_text(chat_id: chat_id, message_id: message_id,
            text: text, disable_web_page_preview: true, reply_markup: add_banned_menu(user_id, username), parse_mode: "markdown")
        end
      end
    end
  end
end
