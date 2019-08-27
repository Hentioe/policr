module Policr
  commander Subfunctions do
    alias FunctionType = SubfunctionType

    def handle(msg, from_nav)
      reply_menu do
        create_menu({
          text:         paste_text,
          reply_markup: create_markup(_group_id, from_nav: from_nav),
        })
      end
    end

    def_text do
      t("subfunctions.desc")
    end

    SELECTED   = "■"
    UNSELECTED = "□"

    def_markup do
      toggle_btn = ->(text : String, type : FunctionType) {
        Button.new(text: text, callback_data: "Subfunctions:#{type.value}:toggle")
      }

      _markup << def_toggle "user_join"
      _markup << def_toggle "bot_join"
      _markup << def_toggle "ban_halal"
      _markup << def_toggle "blacklist"
    end

    private macro def_toggle(type_s)
      {% function_type = type_s.camelcase.id %}
      %symbol = Model::Subfunction.disabled?(_group_id, FunctionType::{{function_type.id}}) ? UNSELECTED : SELECTED
      [
        toggle_btn.call(%symbol + " " + t("subfunctions.{{type_s.id}}"), FunctionType::{{function_type.id}})
      ]
    end
  end
end
