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
        bot.reply msg, text
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end
  end
end
