module Policr
  class WelcomeCommander < Commander
    match :welcome

    def handle(msg)
      reply_menu do
        sended_msg = bot.send_message(
          _chat_id,
          text: text(_group_id, _group_name),
          reply_to_message_id: _reply_msg_id,
          reply_markup: markup(_group_id)
        )

        if sended_msg
          Cache.carving_welcome_setting_msg _chat_id, sended_msg.message_id
        end

        sended_msg
      end
    end

    def_text text do
      welcome_text =
        if welcome = KVStore.get_welcome(_group_id)
          escape_markdown welcome
        else
          t "welcome.none"
        end

      t("welcome.hint", {welcome_text: welcome_text})
    end

    SELECTED   = "■"
    UNSELECTED = "□"

    def markup(group_id)
      make_status = ->(name : String) {
        case name
        when "disable_link_preview"
          KVStore.disabled_welcome_link_preview?(group_id) ? SELECTED : UNSELECTED
        when "welcome"
          KVStore.enabled_welcome?(group_id) ? SELECTED : UNSELECTED
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
