module Policr
  commander Start do
    def handle(msg)
      text = t "start"
      bot.send_message msg.chat.id, text
    end
  end
end
