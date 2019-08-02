module Policr
  commander StrictMode do
    def handle(msg)
      reply_menu do
        bot.send_message(
          _chat_id,
          text: paste_text,
          reply_to_message_id: _reply_msg_id,
          reply_markup: create_markup(_group_id)
        )
      end
    end

    MORE_SYMBOL = "»"
    SELECTED    = "■"
    UNSELECTED  = "□"

    def_text do
      t("strict_mode.desc")
    end

    def create_markup(group_id)
      btn = ->(text : String, name : String) {
        Button.new(text: text, callback_data: "StrictMode:#{name}")
      }
      chk_status = ->(type : String) {
        case type
        when "max_length"
          Model::MaxLength.find(group_id) ? SELECTED : UNSELECTED
        when "content_blocked"
          Model::BlockContent.find(group_id) ? SELECTED : UNSELECTED
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
