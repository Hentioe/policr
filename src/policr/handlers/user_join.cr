module Policr
  class UserJoinHandler < Handler
    alias VerifyStatus = Cache::VerifyStatus
    alias DeleteTarget = Policr::CleanDeleteTarget
    alias EnableStatus = Policr::EnableStatus

    def match(msg)
      all_pass? [
        KVStore.enable_examine?(msg.chat.id),
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
              Schedule.after(5.seconds) { bot.delete_message(chat_id, message_id) } unless KVStore.record_mode?(chat_id)
            end
            return
          end

          # 检测黑名单
          is_blt = detect_blacklist(msg, member) unless Model::Subfunction.disabled?(msg.chat.id, SubfunctionType::Blacklist)
          return if is_blt # 如果是黑名单则无需后续处理
          # 关联并标记入群消息
          Cache.carving_user_join_msg member.id, msg.chat.id, msg.message_id
          # 判断清真
          name = bot.display_name(member)

          midcall HalalMessageHandler do
            if !Model::Subfunction.disabled?(msg.chat.id, SubfunctionType::BanHalal) && handler.is_halal(name)
              # 未关闭封杀清真子功能
              handler.kick_halal_with_receipt(msg, member)
            else
              start_torture(msg, member)
            end
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

    def detect_blacklist(msg, member)
      if report = Model::Report.check_blacklist(member.id) # 处于黑名单中
        text = t "blacklist.was_blocked", {
          user:           FromUser.new(member).markdown_link,
          voting_channel: bot.voting_channel,
          post_id:        report.post_id,
        }
        spawn bot.kick_chat_member(msg.chat.id, member.id)
        bot.send_message msg.chat.id, text, reply_to_message_id: msg.message_id
        true
      else
        false
      end
    end

    AFTER_EVENT_SEC = 60 * 15

    def start_torture(msg, member)
      if Model::Subfunction.disabled?(msg.chat.id, SubfunctionType::UserJoin) # 已关闭子功能
        return
      end
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

        bot.send_message(
          msg.chat.id,
          text: t("after_event.tip"),
          reply_to_message_id: msg.message_id,
          reply_markup: markup
        )
      else
        chat_id = msg.chat.id
        msg_id = msg.message_id
        member_id = member.id
        username = member.username
        promptly_torture(chat_id, msg_id, member_id, username)
      end
    end

    def promptly_torture(chat_id, msg_id, member_id, username, re = false)
      Cache.verify_init(chat_id, member_id) unless re

      params = {chat_id: chat_id}

      send_image = false
      verification =
        if KVStore.custom chat_id
          # 自定义验证
          CustomVerification.new(**params)
        elsif KVStore.dynamic? chat_id
          # 动态验证
          DynamicVerification.new(**params)
        elsif Cache.get_images.size >= 3 && KVStore.enabled_image?(chat_id)
          send_image = true
          # 图片验证
          ImageVerification.new(**params)
        elsif KVStore.enabled_chessboard? chat_id
          # 棋局验证
          GomokuVerification.new(**params)
        else
          # 默认验证
          DefaultVerification.new(**params)
        end

      q = verification.make

      title = q.title
      answers = q.answers

      image =
        if send_image
          q.file_path
        end

      # 禁言用户/异步调用
      spawn bot.restrict_chat_member(chat_id, member_id, can_send_messages: false)

      torture_sec = KVStore.get_torture_sec(chat_id) || DEFAULT_TORTURE_SEC
      question =
        if torture_sec > 0
          hint = t("torture.hint", {user_id: member_id, torture_sec: torture_sec, title: title})
        else
          t("torture.no_time_reply", {user_id: member_id, title: title})
        end
      question = (t("torture.re") + question) if re
      reply_id = msg_id

      btn = ->(text : String, chooese_id : Int32) {
        Button.new(text: text, callback_data: "Torture:#{member_id}:#{username}:#{chooese_id}:#{send_image ? 1 : 0}")
      }
      markup = Markup.new
      i = 0
      answer_list = answers.map do |answer_line|
        tmp_ans = answer_line.map do |answer|
          i += 1
          btn.call(answer, i)
        end
        tmp_ans = tmp_ans.shuffle if q.is_discord
        tmp_ans
      end
      answer_list = answer_list.shuffle if q.is_discord # 乱序答案列表
      answer_list.each { |ans_btns| markup << ans_btns }
      pass_text = t("admin_ope_menu.pass")
      ban_text = t("admin_ope_menu.ban")
      markup << [btn.call(pass_text, 0), btn.call(ban_text, -1)]
      sended_msg =
        if img = image
          bot.send_photo(chat_id, File.new(img), caption: question, reply_to_message_id: reply_id, reply_markup: markup, parse_mode: "markdown")
        else
          bot.send_message(
            chat_id,
            text: question,
            reply_to_message_id: reply_id,
            reply_markup: markup
          )
        end
      if sended_msg
        verification.storage(sended_msg.message_id)
      end
      ban_task = ->(message_id : Int32) {
        if Cache.verify?(chat_id, member_id) == VerifyStatus::Init # 如果仍然是验证初步状态则判定超时
          bot.log "User '#{username}' torture time expired and has been banned"
          Cache.verify_slowed(chat_id, member_id)
          failed(chat_id, message_id, member_id, username, timeout: true, photo: send_image, reply_id: msg_id)
        end
      }

      ban_timer = ->(message_id : Int32) { Schedule.after(torture_sec.seconds) { ban_task.call(message_id) } }
      if sended_msg && (message_id = sended_msg.message_id)
        # 储存被验证的加群消息

        # 存在验证时间，定时任务调用
        ban_timer.call(message_id) if torture_sec > 0
      end
    end

    def failed(chat_id, message_id, user_id, username, admin : FromUser? = nil, timeout = false, photo = false, reply_id : Int32? = nil)
      Cache.verify_status_clear chat_id, user_id
      bot.log "Username '#{username}' has not been verified and has been banned"
      begin
        bot.kick_chat_member(chat_id, user_id)
      rescue ex : TelegramBot::APIException
        text = t "captcha_result.error", {user_id: user_id}
        if photo
          spawn bot.delete_message chat_id, message_id
          bot.send_message chat_id, text, reply_to_message_id: reply_id
        else
          bot.edit_message_text chat_id: chat_id, message_id: message_id, text: text
        end
      else
        text =
          unless admin
            timeout ? t("captcha_result.timeout", {user_id: user_id}) : t("captcha_result.wrong", {user_id: user_id})
          else
            t("captcha_result.admin_ban", {user_id: user_id, admin: admin.markdown_link})
          end

        result_msg_id =
          if photo
            spawn bot.delete_message chat_id, message_id
            sended_msg = bot.send_message(
              chat_id,
              text: text,
              reply_to_message_id: reply_id,
              reply_markup: add_banned_menu(user_id, username)
            )
            if sended_msg
              sended_msg.message_id
            end
          else
            bot.edit_message_text(
              chat_id,
              message_id: message_id,
              text: text,
              reply_markup: add_banned_menu(user_id, username)
            )
            message_id
          end
        if result_msg_id && !admin # 根据干净模式数据延迟清理消息
          delete_target = timeout ? DeleteTarget::TimeoutVerified : DeleteTarget::WrongVerified
          msg_id = result_msg_id
          Model::CleanMode.working(chat_id, delete_target) { bot.delete_message(chat_id, msg_id) }
        end
      end
    end
  end
end
