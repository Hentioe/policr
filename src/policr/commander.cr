module Policr
  abstract class Commander
    getter name : String
    getter bot : Bot

    def initialize(bot, name)
      @bot = bot
      @name = name
    end

    abstract def handle(msg)

  end
end
