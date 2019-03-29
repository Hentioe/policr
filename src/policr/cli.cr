require "admiral"

module Policr::CLI
  class Config
    @@instance = Config.new

    getter prod = false

    def initialize
    end

    private def initialize(@prod)
    end

    def self.init(flags)
      @@instance = self.new(
        flags.prod
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
      default: false,
      long: prod,
      required: true

    def run
      Config.init(flags)
    end
  end
end
