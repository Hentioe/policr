require "./policr/**"
require "dotenv"

module Policr
  VERSION = "0.1.0-dev"

  @@token = "undefined"

  def self.token
    @@token
  end

  def self.start
    CLI::Parser.run
    config = CLI::Config.instance

    unless config.prod
      Dotenv.load! "configs/dev.secret.env"
    end

    @@token = ENV["POLICR_BOT_TOKEN"]? || raise Exception.new("Please provide the bot's Token")
    puts "Start Policr... "
    Bot.new.polling
  end
end

unless (ENV["POLICR_ENV"]? && (ENV["POLICR_ENV"] == "test"))
  Policr.start
end
