require "./policr/**"

Policr::CLI::Parser.run

require "../config/*"
require "dotenv"
require "i18n"

module Policr
  COMMIT     = {{ `git rev-parse --short HEAD`.stringify.strip }}
  VERSION    = "0.1.0-dev (#{COMMIT})"
  ENV_PREFIX = "POLICR_BOT"

  def self.start
    config = CLI::Config.instance

    # 扫描图片集
    scan config.dpath

    Dotenv.load! "config/dev.secret.env" unless config.prod
    DB.connect config.dpath

    I18n.load_path += ["locales"]
    I18n.init
    I18n.default_locale = "zh_hans"

    logger = Logger.new(STDOUT)
    logger.level = Logger::DEBUG
    logger.info "ready to start"

    username = ENV["#{ENV_PREFIX}_USERNAME"]
    token = ENV["#{ENV_PREFIX}_TOKEN"]
    snapshot_channel = ENV["#{ENV_PREFIX}_SNAPSHOT_CHANNEL"]
    voting_channel = ENV["#{ENV_PREFIX}_VOTING_CHANNEL"]

    # test_db

    bot = Bot.new(
      username,
      token,
      logger,
      snapshot_channel,
      voting_channel
    )
    spawn do
      logger.info "start web"
      Web.start logger, bot
    end
    logger.info "start bot"

    bot.polling
  end

  def self.test_db
    
    author_id = 340396281.to_i64
    post_id = 29
    target_id = 871769395.to_i64
    reason = 1
    status = 1
    role = 1
    from_chat = -1001301664514.to_i64

    r1 = Model::Report.create({
      author_id: author_id,
      post_id:   post_id,
      target_id: target_id,
      reason:    reason,
      status:    status,
      role:      role,
      from_chat: from_chat,
    })
    puts "Created result: #{r1.inspect}"
  end
end

Policr.start unless ENV["POLICR_ENV"]? == "test"
