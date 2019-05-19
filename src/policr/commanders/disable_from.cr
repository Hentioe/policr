module Policr
  class DisableFromCommander < Commander
    def initialize(bot)
      super(bot, "disable_from")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        DB.disable_chat_from(msg.chat.id)

        text = t "from.disable"
        text = t "from.disable_with_retain" if DB.get_chat_from(msg.chat.id)
        bot.send_message(msg.chat.id, text, reply_to_message_id: msg.message_id, parse_mode: "markdown")
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end
  end
end
