module Policr
  class TokenCommander < Commander
    def initialize(bot)
      super(bot, "token")
    end

    def handle(msg)
      if msg.chat.type != "private"
        bot.reply msg, "only_private"
        return
      end

      if (user = msg.from) && (groups = KVStore.managed_groups(user.id))
        token = KVStore.gen_token(user.id)

        bot.send_message msg.chat.id, "`#{token}`"
      else
        bot.send_message msg.chat.id, t("no_managed_groups")
      end
    end
  end
end
