module Policr
  class FromSettingHandler < Handler
    def match(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator

      (user = msg.from) && (reply_msg = msg.reply_to_message) && (reply_msg_id = reply_msg.message_id) && Cache.from_setting_msg?(reply_msg_id) && bot.has_permission?(msg.chat.id, user.id, role)
    end

    def handle(msg)
      bot.log "Enable From Investigate for ChatID '#{msg.chat.id}'"
      DB.put_chat_from(msg.chat.id, msg.text)
      bot.reply msg, "已完成设置。"
    end
  end
end
