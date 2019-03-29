require "./policr/**"

module Policr
  VERSION = "0.1.0-dev"

  @@token = "undefined"

  def self.token
    @@token
  end

  def self.start
    @@token = ENV["POLICR_BOT_TOKEN"]? || raise Exception.new("Please provide the bot's Token")
    puts "Start Policr...:"
    Bot.new.polling
  end
end

Policr.start
