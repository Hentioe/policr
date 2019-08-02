module Policr
  commander Subfunctions do
    alias FunctionType = SubfunctionType

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

    def_text do
      t("subfunctions.desc")
    end

    SELECTED   = "■"
    UNSELECTED = "□"

    def create_markup(group_id)
      toggle_btn = ->(text : String, type : FunctionType) {
        Button.new(text: text, callback_data: "Subfunctions:#{type.value}:toggle")
      }

      markup = Markup.new
      markup << def_toggle "user_join"
      markup << def_toggle "bot_join"
      markup << def_toggle "ban_halal"
      markup << def_toggle "blacklist"

      markup
    end

    private macro def_toggle(type_s)
      {% function_type = type_s.camelcase.id %}
      %symbol = Model::Subfunction.disabled?(group_id, FunctionType::{{function_type.id}}) ? UNSELECTED : SELECTED
      [
        toggle_btn.call(%symbol + " " + t("subfunctions.{{type_s.id}}"), FunctionType::{{function_type.id}})
      ]
    end
  end
end
