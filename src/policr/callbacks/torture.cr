module Policr
  class TortureCallback < Callback
    alias VerifyStatus = Cache::VerifyStatus

    def initialize(bot)
      super(bot, "Torture")
    end

    def handle(query, msg, report)
      chat_id = msg.chat.id
      from_user_id = query.from.id
      target_id, target_username, chooese, photo = report

      is_photo = photo.to_i == 1
      chooese_i = chooese.to_i
      target_user_id = target_id.to_i
      message_id = msg.message_id

      join_msg_id =
        if reply_msg = msg.reply_to_message
          reply_msg.message_id
        else
          nil
        end

      if chooese_i <= 0 # 管理员菜单

        if bot.is_admin? chat_id, from_user_id
          bot.log "The administrator ended the torture by: #{chooese_i}"
          case chooese_i
          when 0
            passed(query, chat_id, target_user_id, target_username, message_id, admin: true, photo: is_photo, reply_id: join_msg_id)
          when -1
            failed(chat_id, message_id, target_user_id, target_username, admin: true, photo: is_photo, reply_id: join_msg_id)
          end
        else
          bot.answer_callback_query(query.id, text: t("callback.no_permission"), show_alert: true)
        end
      else
        if target_user_id != from_user_id # 无关人士
          bot.log "Irrelevant User ID '#{from_user_id}' clicked on the verification inline keyboard button"
          bot.answer_callback_query(query.id, text: t("unrelated_warning"), show_alert: true)
          return
        end

        true_index =
        if index = DB.get_true_index(chat_id, msg.message_id)
          index
        else
          bot.log "Did not get the true index"
          chooese_i
        end

        if chooese_i == true_index # 通过验证
          status = Cache.verify?(target_user_id)
          unless status
            midcall UserJoinHandler do
              spawn bot.delete_message chat_id, message_id
              handler.promptly_torture chat_id, join_msg_id, target_user_id, target_username, re: true
              return
            end
          end
          passed(query, chat_id, target_user_id, target_username, message_id, photo: is_photo, reply_id: join_msg_id) if status == VerifyStatus::Init
          slow_with_receipt(query, chat_id, target_user_id, target_username, message_id) if status == VerifyStatus::Slow
        else # 未通过验证
          bot.log "Username '#{target_username}' did not pass verification"
          bot.answer_callback_query(query.id, text: t("no_pass_alert"), show_alert: true)
          failed(chat_id, message_id, target_user_id, target_username, photo: is_photo, reply_id: join_msg_id)
        end
      end
    end

    def passed(query, chat_id, target_user_id, target_username, message_id, admin = false, photo = false, reply_id : Int32? = nil)
      Cache.verify_passed(target_user_id)
      bot.log "Username '#{target_username}' passed verification"
      # 异步调用
      spawn bot.answer_callback_query(query.id, text: t("pass_alert")) unless admin
      enabled_welcome = DB.enabled_welcome? chat_id
      text =
        if enabled_welcome && (welcome = DB.get_welcome chat_id)
          welcome
        elsif admin
          t("pass_by_admin", {user_id: target_user_id})
        else
          t("pass_by_self", {user_id: target_user_id})
        end
      # 异步调用
      if photo
        spawn bot.delete_message chat_id, message_id
        spawn {
          sended_msg = bot.send_message(chat_id: chat_id, text: text, reply_to_message_id: reply_id, reply_markup: nil, parse_mode: "markdown")

          if (temp_msg = sended_msg) && !DB.record_mode?(chat_id) && !enabled_welcome
            msg = temp_msg
            Schedule.after(5.seconds) { bot.delete_message(chat_id, msg.message_id) }
          end
        }
      else
        spawn { bot.edit_message_text(chat_id: chat_id, message_id: message_id,
          text: text, reply_markup: nil, parse_mode: "markdown") }
      end

      # 非记录且没启用欢迎消息模式删除消息
      if !DB.record_mode?(chat_id) && !enabled_welcome && !photo
        Schedule.after(5.seconds) { bot.delete_message(chat_id, message_id) }
      end

      # 初始化用户权限
      bot.restrict_chat_member(chat_id, target_user_id, can_send_messages: true, can_send_media_messages: true, can_send_other_messages: true, can_add_web_page_previews: true)

      # 来源调查
      from_investigate(chat_id, message_id, target_username, target_user_id) if DB.enabled_from?(chat_id)
    end

    def from_investigate(chat_id, message_id, username, user_id)
      bot.log "From investigation of '#{username}'"
      if from_list = DB.get_from(chat_id)
        index = -1
        btn = ->(text : String) {
          Button.new(text: text, callback_data: "From:#{user_id}:#{username}:#{index += 1}")
        }
        markup = Markup.new
        from_list.each do |btn_text_list|
          markup << btn_text_list.map { |text| btn.call(text) }
        end
        reply_to_message_id = Cache.find_join_msg_id(user_id, chat_id)
        bot.send_message(chat_id, t("from.question"), reply_to_message_id: reply_to_message_id, reply_markup: markup)
      end
    end

    private def slow_with_receipt(query, chat_id, target_user_id, target_username, message_id)
      bot.log "Username '#{target_username}' verification is a bit slower"

      # 异步调用
      spawn bot.answer_callback_query(query.id, text: t("pass_slow_alert"))
      spawn { bot.edit_message_text(chat_id: chat_id, message_id: message_id,
        text: t("pass_slow_receipt"), reply_markup: nil) }
      bot.unban_chat_member(chat_id, target_user_id)
    end

    def failed(chat_id, message_id, user_id, username, admin = false, timeout = false, photo = false, reply_id : Int32? = nil)
      midcall UserJoinHandler do
        handler.failed(chat_id, message_id, user_id, username, admin: admin, timeout: timeout, photo: photo, reply_id: reply_id)
      end
    end
  end
end
