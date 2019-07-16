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

    macro match
      def match(msg)
        {{yield}}
      end
    end

    macro handle
      def handle(msg)
        {{yield}}
      end
    end

    def setting_complete_with_delay_delete(msg)
      if sended_msg = bot.reply msg, t("setting_complete")
        msg_id = sended_msg.message_id
        Schedule.after(3.seconds) { bot.delete_message msg.chat.id, msg_id }
      end
    end
  end
end
