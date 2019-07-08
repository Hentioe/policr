require "json" # 下一个 Sqlite3 适配器将会移除
require "jennifer"
require "jennifer_sqlite3_adapter"
require "../../src/policr/cli"

Jennifer::Config.configure do |conf|
  conf.host = "."
  conf.adapter = "sqlite3"
  conf.local_time_zone_name = "UTC"

  env = ENV["POLICR_ENV"]? || "dev"
  conf.host = Policr::CLI::Config.instance.dpath
  conf.db = "#{env}.db"

  conf.logger.level = Logger::INFO
end

Jennifer::Config.from_uri(ENV["DATABASE_URI"]) if ENV.has_key?("DATABASE_URI")
