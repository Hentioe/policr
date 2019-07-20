module Policr
  class WelcomeCommander < Commander
    def initialize(bot)
      super(bot, "welcome")
    end

    def handle(msg)
      role = KVStore.enabled_trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        chat_id = msg.chat.id

        sended_msg = bot.send_message(
          chat_id,
          text: text(chat_id),
          reply_to_message_id: msg.message_id,
          reply_markup: markup(chat_id)
        )

        if sended_msg
          Cache.carving_welcome_setting_msg chat_id, sended_msg.message_id
        end
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end

    def text(chat_id)
      welcome_text =
        if welcome = KVStore.get_welcome(chat_id)
          escape_markdown welcome
        else
          t "welcome.none"
        end
      t "welcome.hint", {welcome_text: welcome_text}
    end

    SELECTED   = "■"
    UNSELECTED = "□"

    def markup(chat_id)
      make_status = ->(name : String) {
        case name
        when "disable_link_preview"
          KVStore.disabled_welcome_link_preview?(chat_id) ? SELECTED : UNSELECTED
        when "welcome"
          KVStore.enabled_welcome?(chat_id) ? SELECTED : UNSELECTED
        else
          UNSELECTED
        end
      }
      make_btn = ->(text : String, name : String) {
        Button.new(text: text, callback_data: "Welcome:#{name}")
      }

      markup = Markup.new

      markup << def_btn_list ["welcome", "disable_link_preview"]

      markup
    end

    macro def_btn_list(list)
      [
      {% for name in list %}
        make_btn.call(make_status.call({{name}}) + " " + t("welcome.{{name.id}}"), {{name}}),
      {% end %}
      ]
    end
  end
end
