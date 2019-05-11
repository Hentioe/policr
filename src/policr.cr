require "./policr/**"
require "dotenv"
require "i18n"
require "i18n/backends/yaml"

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

    Dotenv.load! "configs/dev.secret.env" unless config.prod

    @@token = load_cfg_item("POLICR_BOT_TOKEN")
    @@username = load_cfg_item("POLICR_BOT_USERNAME")

    I18n.backend = I18n::Backends::YAML.new.tap do |backend|
      backend.load_paths << Dir.current + "/locales"
      backend.load
    end
    I18n.locale = "zh_hans"

		puts I18n.t("message.torture.start", {"torture_sec" => "1", "title" => "你好"})

    DB.connect config.dpath
    puts "Start Policr..."
    spawn do
      puts "Start Web..."
      Web.start
    end
    puts "Start Bot..."
    Bot.new.polling
  end

  def load_cfg_item(evar_name)
    ENV[evar_name]? || raise Exception.new("Missing configuration variable: '#{evar_name}'")
  end
end

Policr.start unless (ENV["POLICR_ENV"]? && (ENV["POLICR_ENV"] == "test"))
