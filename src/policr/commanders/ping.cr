module Policr
  class PingCommander < Commander
    def initialize(bot)
      super(bot, "ping")
    end

    def handle(msg)
      spawn bot.delete_message msg.chat.id, msg.message_id
      bot.send_message msg.chat.id, "pong"
    end
  end
end
