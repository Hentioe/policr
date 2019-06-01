module Policr
  class DisableExamineCommander < Commander
    def initialize(bot)
      super(bot, "disable_examine")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        DB.disable_examine(msg.chat.id)
        text = t("examine.disable")
        bot.send_message msg.chat.id, text, reply_to_message_id: msg.message_id, disable_web_page_preview: true, parse_mode: "markdown"
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end
  end
end
