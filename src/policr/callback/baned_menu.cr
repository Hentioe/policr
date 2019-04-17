module Policr
  class BanedMenuCallback < Callback
    def initialize(bot)
      super(bot, "BanedMenu")
    end

    def handle(query, msg, report)
      chat_id = msg.chat.id
      from_user_id = query.from.id
      target_id, target_username, _ = report

      target_user_id = target_id.to_i
      message_id = msg.message_id

      role = DB.trust_admin?(chat_id) ? :admin : :creator

      unless bot.has_permission? chat_id, from_user_id, role
        bot.log "User ID '#{from_user_id}' without permission click to unbanned button"
        bot.answer_callback_query(query.id, text: "你既然不是管理员，那就是他的同伙，不听你的", show_alert: true)
        return
      end

      begin
        bot.log "Username '#{target_username}' has been unbanned by the administrator"
        unban_r = bot.unban_chat_member(chat_id, target_user_id)
        markup = Markup.new
        markup << Button.new(text: "叫 TA 回来", url: "t.me/#{target_username}")
        bot.edit_message_text(chat_id: chat_id, message_id: message_id,
          text: "(,,・ω・,,) 已经被解封了，让他注意。", reply_markup: markup) if unban_r
      rescue ex : TelegramBot::APIException
        _, reason = bot.get_error_code_with_reason(ex)
        bot.answer_callback_query(query.id, text: "解封失败，#{reason}", show_alert: true)
        bot.log "Username '#{target_username}' unsealing failed, reason: #{reason}"
      end
    end
  end
end
