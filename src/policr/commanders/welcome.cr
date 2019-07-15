module Policr
  class WelcomeCommander < Commander
    def initialize(bot)
      super(bot, "welcome")
    end

    def handle(msg)
      role = KVStore.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        chat_id = msg.chat.id

        sended_msg = bot.send_message msg.chat.id, text(chat_id), reply_to_message_id: msg.message_id

        if sended_msg
          Cache.carving_welcome_setting_msg chat_id, sended_msg.message_id
        end
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end

    def text(chat_id)
      welcome_text =
        if welcome = KVStore.get_welcome(chat_id)
          welcome
        else
          t "welcome.none"
        end
      t "welcome.hint", {welcome_text: welcome_text}
    end
  end
end
