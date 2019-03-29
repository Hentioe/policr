require "telegram_bot"

module Policr
  class Bot < TelegramBot::Bot
    include TelegramBot::CmdHandler

    def initialize
      super("PolicrBot", Policr.token)

      cmd "hello" do |msg|
        reply msg, "world!"
      end

      # /add 5 7 => 12
      cmd "add" do |msg, params|
        reply msg, "#{params[0].to_i + params[1].to_i}"
      end
    end
  end
end
