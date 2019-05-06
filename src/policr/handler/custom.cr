module Policr
  class CustomHandler < Handler
    def match(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator

      (user = msg.from) && (reply_msg = msg.reply_to_message) && (reply_msg_id = reply_msg.message_id) && Cache.custom_msg?(reply_msg_id) && bot.has_permission?(msg.chat.id, user.id, role)
    end

    def handle(msg)
      bot.log "Custom verification for chat_id '#{msg.chat.id}'"
      puts msg.text
      bot.reply msg, "功能实现中……"
    end
  end
end
