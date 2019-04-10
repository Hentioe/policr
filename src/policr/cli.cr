require "admiral"

module Policr::CLI
  DEFAULT_DPATH = "."
  DEFAULT_PROD  = false
  DEFAULT_PORT  = 8080

  class Config
    @@instance = Config.new

    getter prod = DEFAULT_PROD
    getter dpath = DEFAULT_DPATH
    getter port = DEFAULT_PORT

    def initialize
    end

    private def initialize(@prod, @dpath, @port)
    end

    def self.init(flags)
      @@instance = self.new(
        flags.prod,
        flags.dpath,
        flags.port
      )
    end

    def self.instance
      @@instance
    end
  end

  class Parser < Admiral::Command
    define_help description: "Telegram bot focused on reviewing group members"

    define_flag prod : Bool,
      description: "Running in production mode",
      default: DEFAULT_PROD,
      long: prod,
      required: true

    define_flag dpath : String,
      description: "Data path (does not contain data directory)",
      default: DEFAULT_DPATH,
      long: dpath,
      required: true

    define_flag port : Int32,
      description: "Web server listening port",
      default: DEFAULT_PORT,
      long: port,
      short: p,
      required: true

    def run
      Config.init(flags)
    end
  end
end
