module Policr
  abstract class Handler
    macro all_pass?(conditions)
      {% for condition, index in conditions %}
        {{condition}} {% if index < conditions.size - 1 %} && {% end %}
      {% end %}
    end

    getter bot : Bot

    def initialize(bot_instance)
      @bot = bot_instance
    end

    def registry(msg)
      preprocess msg
    end

    private def preprocess(msg)
      handle(msg) if match(msg)
    end

    abstract def match(msg)
    abstract def handle(msg)
  end
end
