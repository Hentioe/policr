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

    I18n.load_path += ["locales/**/"]
    I18n.init
    I18n.default_locale = "zh-hans"

    logger = Logger.new(STDOUT)
    logger.level = config.prod ? Logger::INFO : Logger::DEBUG
    logger.info "ready to start"

    data = {
      username:           from_env("username"),
      token:              from_env("token"),
      owner_id:           from_env("owner_id"),
      community_group_id: from_env("community_group_id"),
      snapshot_channel:   from_env("snapshot_channel"),
      voting_channel:     from_env("voting_channel"),
      logger:             logger,
    }
    bot = Bot.new **data
    spawn do
      logger.info "start web"
      Web.start logger, bot
    end
    logger.info "start bot"
    Cache.recompile_global_rules bot

    bot.polling
  end

  private macro from_env(var_name)
    ENV["#{ENV_PREFIX}_{{var_name.upcase.id}}"]
  end
end

Policr.start unless ENV["POLICR_ENV"]? == "test"
