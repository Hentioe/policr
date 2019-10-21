require "jennifer"
require "jennifer_sqlite3_adapter"

Jennifer::Config.configure do |conf|
  conf.host = "."
  conf.adapter = "sqlite3"
  conf.local_time_zone_name = "UTC"

  env = ENV["POLICR_ENV"]? || "dev"
  conf.host = ENV["POLICR_DATABASE_HOST"]? || "./data"
  conf.db = "#{env}.db"

  level = env == "prod" ? Logger::INFO : Logger::DEBUG
  conf.logger.level = level
end

Jennifer::Config.from_uri(ENV["POLICR_DATABASE_URI"]) if ENV.has_key?("POLICR_DATABASE_URI")
