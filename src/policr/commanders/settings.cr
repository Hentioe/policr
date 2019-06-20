module Policr
  class SettingsCommander < Commander
    def initialize(bot)
      super(bot, "settings")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        bot.send_message msg.chat.id, t("settings.desc", {last_change: t("settings.none")}), reply_to_message_id: msg.message_id, reply_markup: create_markup(msg.chat.id), parse_mode: "markdown"
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end

    SELECTED   = "■"
    UNSELECTED = "□"

    def create_markup(chat_id)
      toggle_btn = ->(text : String, name : String) {
        Button.new(text: text, callback_data: "Settings:#{name}:toggle")
      }
      make_status = ->(name : String) {
        case name
        when "enable_examine"
          DB.enable_examine?(chat_id) ? SELECTED : UNSELECTED
        when "trust_admin"
          DB.trust_admin?(chat_id) ? SELECTED : UNSELECTED
        when "record_mode"
          DB.record_mode?(chat_id) ? SELECTED : UNSELECTED
        when "enable_from"
          DB.enabled_from?(chat_id) ? SELECTED : UNSELECTED
        when "welcome"
          DB.enabled_welcome?(chat_id) ? SELECTED : UNSELECTED
        when "fault_tolerance"
          DB.fault_tolerance?(chat_id) ? SELECTED : UNSELECTED
        else
          UNSELECTED
        end
      }

      markup = Markup.new
      markup << def_toggle "enable_examine"
      markup << def_toggle "trust_admin"
      markup << def_toggle "record_mode"
      markup << def_toggle "enable_from"
      markup << def_toggle "welcome"
      markup << def_toggle "fault_tolerance"

      markup
    end

    private macro def_toggle(name)
      [
        toggle_btn.call(make_status.call({{name}}) + " " + t("settings.{{name.id}}"), {{name}})
      ]
    end
  end
end
