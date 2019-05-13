module Policr
  class TortureCallback < Callback
    alias VerifyStatus = Cache::VerifyStatus

    def initialize(bot)
      super(bot, "Torture")
    end

    def handle(query, msg, report)
      chat_id = msg.chat.id
      from_user_id = query.from.id
      target_id, target_username, chooese = report

      chooese_i = chooese.to_i
      target_user_id = target_id.to_i
      message_id = msg.message_id

      custom = DB.custom(msg.chat.id)
      true_index = custom ? custom.[0] : 1

      if chooese_i <= 0 # 管理员菜单
        role = DB.trust_admin?(chat_id) ? :admin : :creator

        if bot.has_permission? chat_id, from_user_id, role
          bot.log "The administrator ended the torture by: #{chooese_i}"
          case chooese_i
          when 0
            verified_with_receipt(query, chat_id, target_user_id, target_username, message_id, admin: true)
          when -1
            unverified_with_receipt(chat_id, message_id, target_user_id, target_username, admin: true)
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

        if chooese_i == true_index # 通过验证
          status = Cache.verify?(target_user_id)
          verified_with_receipt(query, chat_id, target_user_id, target_username, message_id) if status == VerifyStatus::Init
          slow_with_receipt(query, chat_id, target_user_id, target_username, message_id) if status == VerifyStatus::Slow
        else # 未通过验证
          bot.log "Username '#{target_username}' did not pass verification"
          bot.answer_callback_query(query.id, text: t("no_pass_alert"), show_alert: true)
          unverified_with_receipt(chat_id, message_id, target_user_id, target_username)
        end
      end
    end

    def verified_with_receipt(query, chat_id, target_user_id, target_username, message_id, admin = false)
      Cache.verify_passed(target_user_id)
      bot.log "Username '#{target_username}' passed verification"

      bot.answer_callback_query(query.id, text: "pass_alert", show_alert: true) unless admin
      text = t("pass_by_self")
      text = t("pass_by_admin") if admin

      bot.edit_message_text(chat_id: chat_id, message_id: message_id,
        text: text, reply_markup: nil)

      # 干净模式删除消息
      Schedule.after(5.seconds) { bot.delete_message(chat_id, message_id) } if DB.clean_mode?(chat_id)

      # 初始化用户权限
      bot.restrict_chat_member(chat_id, target_user_id, can_send_messages: true, can_send_media_messages: true, can_send_other_messages: true, can_add_web_page_previews: true)

      # 来源调查
      from_investigate(chat_id, message_id, target_username, target_user_id) if DB.enabled_from?(chat_id)
    end

    def from_investigate(chat_id, message_id, username, user_id)
      bot.log "From investigation of '#{username}'"
      if from_list = DB.get_chat_from(chat_id)
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

      bot.answer_callback_query(query.id, text: t("pass_slow_alert"), show_alert: true)
      bot.edit_message_text(chat_id: chat_id, message_id: message_id,
        text: t("pass_slow_receipt"), reply_markup: nil)
      bot.unban_chat_member(chat_id, target_user_id)
    end

    def unverified_with_receipt(chat_id, message_id, user_id, username, admin = false)
      if (handler = bot.handlers[:join_user]?) && handler.is_a?(JoinUserHandler)
        handler.unverified_with_receipt(chat_id, message_id, user_id, username, admin)
      end
    end
  end
end
