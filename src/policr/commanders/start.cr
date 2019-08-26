module Policr
  commander Start do
    def handle(msg, from_nav)
      text = t "start"
      chat_id = msg.chat.id

      bot.send_message chat_id, text, reply_markup: create_markup(chat_id)
    end

    def_markup do
    end
  end
end
