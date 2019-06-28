require "jennifer"
require "jennifer_sqlite3_adapter"

Jennifer::Config.read("config/database.yml", ENV["POLICR_ENV"]? || "dev")
Jennifer::Config.from_uri(ENV["DATABASE_URI"]) if ENV.has_key?("DATABASE_URI")

Jennifer::Config.configure do |conf|
  conf.logger.level = Logger::DEBUG
end
