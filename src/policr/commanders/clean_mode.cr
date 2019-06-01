module Policr
  class EnableCleanModeCommander < Commander
    def initialize(bot)
      super(bot, "clean_mode")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        text = t "clean_mode.reply"
        DB.clean_mode(msg.chat.id)
        bot.send_message msg.chat.id, text, reply_to_message_id: msg.message_id, disable_web_page_preview: true, parse_mode: "markdown"
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end
  end
end
