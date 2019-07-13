module Policr
  class StrictModeCommander < Commander
    def initialize(bot)
      super(bot, "strict_mode")
    end

    def handle(msg)
      role = KVStore.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        bot.send_message msg.chat.id, t("strict_mode.desc"), reply_to_message_id: msg.message_id, reply_markup: create_markup(msg.chat.id), parse_mode: "markdown"
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end

    MORE_SYMBOL = "»"
    SELECTED    = "■"
    UNSELECTED  = "□"

    def create_markup(chat_id)
      btn = ->(text : String, name : String) {
        Button.new(text: text, callback_data: "StrictMode:#{name}")
      }
      chk_status = ->(type : String) {
        case type
        when "max_length"
          Model::MaxLength.find(chat_id) ? SELECTED : UNSELECTED
        when "content_blocked"
          UNSELECTED
        end
      }
      markup = Markup.new
      def_button_list ["max_length", "content_blocked"]

      markup
    end

    macro def_button_list(item_list)
      {% for item in item_list %}
        markup << [
                    btn.call("#{chk_status.call({{item}})} #{t("strict_mode.{{item.id}}")}", {{item}}),
                    btn.call("#{t("strict_mode.{{item.id}}_setting")} #{MORE_SYMBOL}", "{{item.id}}_setting")
                  ]
      {% end %}
    end
  end
end
