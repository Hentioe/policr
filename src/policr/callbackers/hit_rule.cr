module Policr
  callbacker HitRule do
    def handle(query, msg, data)
      chat_id = msg.chat.id
      msg_id = msg.message_id
      from_user_id = query.from.id

      operate, target_user_id = data
      target_user_id = target_user_id.to_i

      role = Model::Toggle.trusted_admin?(chat_id) ? :admin : :creator
      unless bot.has_permission?(chat_id, from_user_id, role)
        bot.answer_callback_query(query.id, text: t("callback.no_permission"), show_alert: true)
        return
      end

      case operate
      when "restrict"
        bot.restrict chat_id, target_user_id
      when "derestrict"
        bot.derestrict chat_id, target_user_id
      when "ban"
        bot.kick_chat_member chat_id, target_user_id
      when "unban"
        bot.unban_chat_member chat_id, target_user_id
      else # 失效键盘
        invalid_keyboard
        return
      end
      bot.delete_message chat_id, msg_id
    end
  end
end
