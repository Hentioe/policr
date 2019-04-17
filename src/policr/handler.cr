module Policr
  abstract class Handler
    getter bot : Bot
    @current_msg : TelegramBot::Message?

    def initialize(bot_instance)
      @bot = bot_instance
    end

    def registry(msg)
      @current_msg = msg
      preprocess
    end

    private def preprocess
      if (msg = @current_msg) && match(msg)
        handle(msg)
      end
    end

    abstract def match(msg)
    abstract def handle(msg)
  end
end
