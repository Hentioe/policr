require "./policr/**"
require "dotenv"
require "i18n"

module Policr
  extend self

  COMMIT  = {{ `git rev-parse --short HEAD`.stringify.strip }}
  VERSION = "0.1.0-dev (#{COMMIT})"

  UNDEFINED = "undefined"

  @@username = UNDEFINED
  @@token = UNDEFINED
  @@logger : Logger?

  def token
    @@token
  end

  def username
    @@username
  end

  def logger
    @@logger
  end

  def start
    CLI::Parser.run
    config = CLI::Config.instance

    Dotenv.load! "configs/dev.secret.env" unless config.prod

    @@token = load_cfg_item("POLICR_BOT_TOKEN")
    @@username = load_cfg_item("POLICR_BOT_USERNAME")

    DB.connect config.dpath

    I18n.load_path += ["locales"]
    I18n.init
    I18n.default_locale = "zh_hans"

    logger = Logger.new(STDOUT)
    logger.level = Logger::DEBUG
    @@logger = logger

    logger.info "ready to start"
    spawn do
      logger.info "start web"
      Web.start
    end
    logger.info "start bot"
    Bot.new.polling
  end

  def load_cfg_item(evar_name)
    ENV[evar_name]? || raise Exception.new("missing configuration variable: '#{evar_name}'")
  end
end

Policr.start unless (ENV["POLICR_ENV"]? && (ENV["POLICR_ENV"] == "test"))
