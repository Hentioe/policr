module Policr
  class PingCommander < Commander
    def initialize(bot)
      super(bot, "ping")
    end

    def handle(msg)
      bot.reply msg, "pong"
    end
  end
end
