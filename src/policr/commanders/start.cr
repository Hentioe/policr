module Policr
  class StartCommander < Commander
    def initialize(bot)
      super(bot, "start")
    end

    def handle(msg)
      text = t "start"
      bot.send_message msg.chat.id, text
    end
  end
end
