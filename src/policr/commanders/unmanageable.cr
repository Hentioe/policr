module Policr
  class UnmanageableCommander < Commander
    def initialize(bot)
      super(bot, "unmanageable")
    end

    def handle(msg)
      if msg.chat.type != "supergroup" && msg.chat.type != "group"
        bot.reply msg, t("only_group")
      end

      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, :creator)
        DB.delete_managed_group(user.id, msg.chat.id)
        bot.reply msg, t("unmanageable.success")
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end
  end
end
