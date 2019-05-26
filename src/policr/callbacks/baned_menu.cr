module Policr
  class BanedMenuCallback < Callback
    def initialize(bot)
      super(bot, "BanedMenu")
    end

    def handle(query, msg, report)
      chat_id = msg.chat.id
      from_user_id = query.from.id
      target_id, target_username, ope = report

      target_user_id = target_id.to_i
      message_id = msg.message_id

      unless bot.is_admin? chat_id, from_user_id
        bot.log "User ID '#{from_user_id}' without permission click to unbanned button"
        bot.answer_callback_query(query.id, text: t("callback.no_permission"))
        return
      end

      ope_count =
        case ope
        when "unban"
          0
        when "whitelist"
          1
        else
          -1
        end

      if ope_count < 0
        return
      end

      begin
        bot.log "Username '#{target_username}' has been unbanned by the administrator"
        unban_r = bot.unban_chat_member(chat_id, target_user_id)
        msg = t "unban_message", {user_id: target_user_id}
        msg = t("add_to_whitelist") if ope_count == 1
        bot.edit_message_text(chat_id: chat_id, message_id: message_id,
          text: msg, parse_mode: "markdown") if unban_r
        # 加入白名单
        DB.add_to_whitelist(target_user_id) if ope_count == 1
      rescue ex : TelegramBot::APIException
        _, reason = bot.get_error_code_with_reason(ex)
        bot.answer_callback_query(query.id, text: "#{t("unban_error")}#{reason}")
        bot.log "Username '#{target_username}' unsealing failed, reason: #{reason}"
      end
    end
  end
end
