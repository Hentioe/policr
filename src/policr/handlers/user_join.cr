module Policr
  handler UserJoin do
    alias DeleteTarget = CleanDeleteTarget
    alias AntiTarget = AntiMessageDeleteTarget

    match do
      all_pass? [
        KVStore.enabled_examine?(msg.chat.id),
        msg.new_chat_members,
      ]
    end

    handle do
      chat_id = msg.chat.id

      if members = msg.new_chat_members
        members.select { |m| m.is_bot == false }.each do |member|
          # 管理员拉入，放行
          if (user = msg.from) && (user.id != member.id) && bot.is_admin?(msg.chat.id, user.id)
            if (sended_msg = bot.reply(msg, t("add_from_admin"))) && (message_id = sended_msg.message_id)
              Schedule.after(5.seconds) { bot.delete_message(chat_id, message_id) } unless KVStore.enabled_record_mode?(chat_id)
            end
            # 删除入群消息
            Model::AntiMessage.working chat_id, AntiTarget::JoinGroup do
              spawn bot.delete_message(chat_id, msg.message_id)
            end
            bot.send_welcome(
              msg.chat,
              msg.message_id,
              FromUser.new(member),
              reply: true,
              reply_id: msg.message_id,
              last_delete: false
            ) if KVStore.enabled_welcome?(chat_id)
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
            if !Model::Subfunction.disabled?(msg.chat.id, SubfunctionType::BanHalal) && # 未关闭封杀清真子功能
               handler.is_halal(name) &&
               !KVStore.halal_white?(member.id) # 非白名单
              _handler.kick_halal(msg, member)
            else
              start_torture(msg, member)
            end
          end
        end
      end
    end

    def add_banned_menu(user_id, is_halal = false)
      markup = Markup.new
      markup << Button.new(text: t("baned_menu.unban"), callback_data: "BanedMenu:#{user_id}:_:unban")
      markup << Button.new(text: t("baned_menu.whitelist"), callback_data: "BanedMenu:#{user_id}:_:whitelist") if is_halal
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
    MAX_COUNTDOWN   = 60*60*24*3 # 最大倒计时 3 天

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
          Button.new(text: text, callback_data: "AfterEvent:#{member.id}:_:#{item}:#{msg.message_id}")
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
        promptly_torture(chat_id, msg_id, member_id)
      end
    end

    def promptly_torture(chat_id : Int64, msg_id : (Int32 | Nil), member_id : Int32, re = false)
      Cache.verification_init(chat_id, member_id) unless re

      params = {chat_id: chat_id}

      send_image = false
      verification =
        if KVStore.custom chat_id
          # 自定义验证
          CustomVerification.new(**params)
        elsif KVStore.enabled_dynamic_captcha? chat_id
          # 动态验证
          DynamicVerification.new(**params)
        elsif Cache.get_images.size >= 3 && KVStore.enabled_image_captcha?(chat_id)
          send_image = true
          # 图片验证
          ImageVerification.new(**params)
        elsif KVStore.enabled_chessboard_captcha? chat_id
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
      locale = gen_locale chat_id
      question =
        if torture_sec > 0 && torture_sec < MAX_COUNTDOWN
          hint = t("torture.hint", {user_id: member_id, torture_sec: torture_sec, title: title}, locale: locale)
        else
          t("torture.no_time_reply", {user_id: member_id, title: title}, locale: locale)
        end
      question = (t("torture.re") + question) if re
      reply_id = msg_id

      btn = ->(text : String, chooese_id : Int32) {
        Button.new(text: text, callback_data: "Torture:#{member_id}:_:#{chooese_id}:#{send_image ? 1 : 0}")
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
          bot.send_photo(
            chat_id,
            File.new(img),
            caption: question,
            reply_to_message_id: reply_id,
            reply_markup: markup,
            parse_mode: "markdown"
          )
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
        if Cache.verification?(chat_id, member_id) == VerificationStatus::Init # 如果仍然是验证初步状态则判定超时
          Cache.verification_slowed(chat_id, member_id)
          failed(chat_id, message_id, member_id, timeout: true, photo: send_image, reply_id: msg_id)
        end
      }

      ban_timer = ->(message_id : Int32) { Schedule.after(torture_sec.seconds) { ban_task.call(message_id) } }
      if sended_msg && (message_id = sended_msg.message_id)
        # 存在验证时间，定时任务调用
        ban_timer.call(message_id) if torture_sec > 0
      end
    end

    KICK_ISSUE_IS_ADMIN   = "Bad Request: user is an administrator of the chat"
    KICK_ISSUE_NOT_RIGHTS = "Bad Request: not enough rights to restrict/unrestrict chat member"

    def failed(chat_id, message_id, user_id, admin : FromUser? = nil, timeout = false, photo = false, reply_id : Int32? = nil)
      Cache.verification_status_clear chat_id, user_id
      begin
        bot.kick_chat_member(chat_id, user_id)
      rescue ex : TelegramBot::APIException
        _, reason = bot.parse_error ex
        reason =
          case reason
          when KICK_ISSUE_IS_ADMIN
            t "captcha_result.error.is_admin"
          when KICK_ISSUE_NOT_RIGHTS
            t "captcha_result.error.not_rights"
          else
            reason
          end
        text = t "captcha_result.error.desc", {user_id: user_id, reason: reason}
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
              reply_markup: add_banned_menu(user_id)
            )
            if sended_msg
              sended_msg.message_id
            end
          else
            bot.edit_message_text(
              chat_id,
              message_id: message_id,
              text: text,
              reply_markup: add_banned_menu(user_id)
            )
            message_id
          end
        if result_msg_id && !admin # 根据干净模式数据延迟清理消息
          delete_target = timeout ? DeleteTarget::TimeoutVerified : DeleteTarget::WrongVerified
          msg_id = result_msg_id
          Model::CleanMode.working chat_id, delete_target do
            # 删除加群消息
            Model::AntiMessage.working chat_id, AntiTarget::JoinGroup do
              if _delete_msg_id = reply_id
                spawn bot.delete_message(chat_id, _delete_msg_id)
              end
            end
            # 清理消息
            bot.delete_message(chat_id, msg_id)
          end
        end
      end
    end
  end
end
