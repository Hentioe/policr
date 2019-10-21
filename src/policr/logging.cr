require "logger"

module Policr::Logging
  @@logger : Logger?

  def self.init(level : String)
    level = Logger::Severity.parse?(level) || Logger::UNKNOWN
    logger = Logger.new(STDOUT)
    logger.level = level
    @@logger = logger
  end

  macro def_log_puts(levels)
    {% for level in levels %}
      def self.{{level.id}}(msg)
        (@@logger || self.init("debug")).{{level}} msg
      end
    {% end %}
  end

  def self.get_logger
    @@logger || init("debug")
  end

  def_log_puts [debug, error, fatal, info, unknown, warn]
end
