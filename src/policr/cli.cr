require "admiral"

module Policr::CLI
  DEFAULT_DPATH = "."
  DEFAULT_PROD  = false

  class Config
    @@instance = Config.new

    getter prod = DEFAULT_PROD
    getter dpath = DEFAULT_DPATH

    def initialize
    end

    private def initialize(@prod, @dpath)
    end

    def self.init(flags)
      @@instance = self.new(
        flags.prod,
        flags.dpath
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

    def run
      Config.init(flags)
    end
  end
end
