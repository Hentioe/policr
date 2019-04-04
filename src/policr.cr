require "./policr/**"
require "dotenv"

module Policr
  extend self

  VERSION = "0.1.0-dev"

  UNDEFINED = "undefined"

  @@username = UNDEFINED
  @@token = UNDEFINED

  def token
    @@token
  end

  def username
    @@username
  end

  def start
    CLI::Parser.run
    config = CLI::Config.instance

    unless config.prod
      Dotenv.load! "configs/dev.secret.env"
    end

    @@token = ENV["POLICR_BOT_TOKEN"]? || raise Exception.new("Please provide the bot's Token")
    @@username = ENV["POLICR_BOT_USERNAME"]? || raise Exception.new("Please provide the bot's Username")
    DB.connect config.dpath
    puts "Start Policr..."
    Bot.new.polling
  end
end

unless (ENV["POLICR_ENV"]? && (ENV["POLICR_ENV"] == "test"))
  Policr.start
end
