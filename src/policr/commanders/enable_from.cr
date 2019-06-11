module Policr
  class EnableFromCommander < Commander
    def initialize(bot)
      super(bot, "enable_from")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        if DB.get_from(msg.chat.id)
          DB.enable_from(msg.chat.id)
          text = t "from.enable"
          bot.send_message(msg.chat.id, text, reply_to_message_id: msg.message_id, parse_mode: "markdown")
        else
          text = t "from.enable_need_set"
          bot.send_message(msg.chat.id, text, reply_to_message_id: msg.message_id, parse_mode: "markdown")
        end
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end
  end
end
