module Policr
  abstract class Callback
    getter bot : Bot
    getter name : String

    @current_query : TelegramBot::CallbackQuery?

    def initialize(bot, name)
      @bot = bot
      @name = name
    end

    def match?(call_name)
      call_name == @name
    end

    abstract def handle(query, msg, report)
  end
end
