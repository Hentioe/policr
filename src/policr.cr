require "./policr/**"

Policr::CLI::Parser.run

require "../config/*"
require "dotenv"
require "i18n"

module Policr
  ENV_PREFIX = "POLICR_BOT"

  def self.start
    config = CLI::Config.instance

    # 扫描图片集
    scan config.dpath

    Dotenv.load! "config/dev.secret.env" unless config.prod
    KVStore.connect config.dpath

    I18n.load_path += ["locales"]
    I18n.init
    I18n.default_locale = "zh-hans"

    logger = Logger.new(STDOUT)
    logger.level = config.prod ? Logger::INFO : Logger::DEBUG
    logger.info "ready to start"

    bot = Bot.new(
      from_env("USERNAME"),
      from_env("TOKEN"),
      from_env("OWNER_ID"),
      logger,
      from_env("SNAPSHOT_CHANNEL"),
      from_env("VOTING_CHANNEL")
    )
    spawn do
      logger.info "start web"
      Web.start logger, bot
    end
    logger.info "start bot"

    bot.polling
  end

  private macro from_env(var_name)
    ENV["#{ENV_PREFIX}_{{var_name.upcase.id}}"]
  end
end

Policr.start unless ENV["POLICR_ENV"]? == "test"
