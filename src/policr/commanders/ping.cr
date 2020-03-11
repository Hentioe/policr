module Policr
  commander Ping do
    def handle(msg, from_nav)
      spawn bot.delete_message msg.chat.id, msg.message_id
      sended_msg = bot.send_message msg.chat.id, "🏓"
      if sended_msg
        tmp_msg = sended_msg
        Schedule.after(15.seconds) { bot.delete_message msg.chat.id, tmp_msg.message_id }
      end
    end
  end
end
