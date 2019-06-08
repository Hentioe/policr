module Policr
  abstract class Handler
    macro all_pass?(conditions)
      {% for condition, index in conditions %}
        {{condition}} {% if index < conditions.size - 1 %} && {% end %}
      {% end %}
    end

    macro allow_edit
      def initialize(@bot)
        super

        @allow_edit = true
      end
    end

    getter allow_edit = false
    getter bot : Bot

    def initialize(@bot)
    end

    def registry(msg, from_edit = false)
      unless from_edit
        preprocess msg
      else
        preprocess(msg) if @allow_edit
      end
    end

    private def preprocess(msg)
      handle(msg) if match(msg)
    end

    abstract def match(msg)
    abstract def handle(msg)
  end
end
