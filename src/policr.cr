require "./policr/**"
require "dotenv"
require "i18n"

module Policr
  COMMIT     = {{ `git rev-parse --short HEAD`.stringify.strip }}
  VERSION    = "0.1.0-dev (#{COMMIT})"
  ENV_PREFIX = "POLICR_BOT"

  def self.start
    CLI::Parser.run
    config = CLI::Config.instance

    Dotenv.load! "configs/dev.secret.env" unless config.prod
    DB.connect config.dpath

    I18n.load_path += ["locales"]
    I18n.init
    I18n.default_locale = "zh_hans"

    logger = Logger.new(STDOUT)
    logger.level = Logger::DEBUG
    logger.info "ready to start"

    username = ENV["#{ENV_PREFIX}_USERNAME"]
    token = ENV["#{ENV_PREFIX}_TOKEN"]

    bot = Bot.new(username, token, logger)
    spawn do
      logger.info "start web"
      Web.start logger, bot
    end
    logger.info "start bot"

    bot.polling
  end
end

Policr.start unless ENV["POLICR_ENV"]? == "test"
