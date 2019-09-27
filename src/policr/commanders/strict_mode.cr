module Policr
  commander StrictMode do
    def handle(msg, from_nav)
      reply_menu do
        create_menu({
          text:         paste_text,
          reply_markup: paste_markup,
        })
      end
    end

    MORE_SYMBOL = "»"
    SELECTED    = "■"
    UNSELECTED  = "□"

    def_text do
      t("strict_mode.desc")
    end

    def_markup do
      btn = ->(text : String, name : String) {
        Button.new(text: text, callback_data: "StrictMode:#{name}")
      }
      chk_status = ->(type : String) {
        case type
        when "max_length"
          Model::MaxLength.find(_group_id) ? SELECTED : UNSELECTED
        when "blocked_content"
          Model::BlockRule.enabled?(_group_id) ? SELECTED : UNSELECTED
        when "format_limit"
          Model::FormatLimit.find(_group_id) ? SELECTED : UNSELECTED
        end
      }
      def_button_list ["max_length", "blocked_content", "format_limit"]
    end

    macro def_button_list(item_list)
      {% for item in item_list %}
        _markup << [
                    btn.call("#{chk_status.call({{item}})} #{t("strict_mode.{{item.id}}")}", {{item}}),
                    btn.call("#{t("strict_mode.{{item.id}}_setting")} #{MORE_SYMBOL}", "{{item.id}}_setting")
                  ]
      {% end %}
    end
  end
end
