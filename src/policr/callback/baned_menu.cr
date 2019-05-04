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

      role = DB.trust_admin?(chat_id) ? :admin : :creator

      unless bot.has_permission? chat_id, from_user_id, role
        bot.log "User ID '#{from_user_id}' without permission click to unbanned button"
        bot.answer_callback_query(query.id, text: "你怕不是他的同伙吧？不听你的", show_alert: true)
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
        markup = Markup.new
        markup << Button.new(text: "叫 TA 回来", url: "t.me/#{target_username}")
        msg = "(,,・ω・,,) 已经被解封了，让他注意。"
        msg = "(,,・ω・,,) 已被解封并加入到白名单，下次不会再干他了。" if ope_count == 1
        bot.edit_message_text(chat_id: chat_id, message_id: message_id,
          text: msg, reply_markup: markup) if unban_r
        # 加入白名单
        DB.add_to_whitelist(target_user_id) if ope_count == 1
      rescue ex : TelegramBot::APIException
        _, reason = bot.get_error_code_with_reason(ex)
        bot.answer_callback_query(query.id, text: "解封失败，#{reason}", show_alert: true)
        bot.log "Username '#{target_username}' unsealing failed, reason: #{reason}"
      end
    end
  end
end
