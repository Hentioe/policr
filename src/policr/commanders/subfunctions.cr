module Policr
  class SubfunctionsCommander < Commander
    alias FunctionType = SubfunctionType

    def initialize(bot)
      super(bot, "subfunctions")
    end

    def handle(msg)
      role = KVStore.enabled_trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        bot.send_message(
          msg.chat.id,
          text: t("subfunctions.desc"),
          reply_to_message_id: msg.message_id,
          reply_markup: create_markup(msg.chat.id)
        )
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end

    SELECTED   = "■"
    UNSELECTED = "□"

    def create_markup(chat_id)
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
      %symbol = Model::Subfunction.disabled?(chat_id, FunctionType::{{function_type.id}}) ? UNSELECTED : SELECTED
      [
        toggle_btn.call(%symbol + " " + t("subfunctions.{{type_s.id}}"), FunctionType::{{function_type.id}})
      ]
    end
  end
end
