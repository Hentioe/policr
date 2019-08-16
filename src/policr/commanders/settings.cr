module Policr
  commander Settings do
    def handle(msg)
      reply_menu do
        bot.send_message(
          _chat_id,
          text: create_text(_group_id, t("settings.none"), _group_name),
          reply_to_message_id: _reply_msg_id,
          reply_markup: create_markup(_group_id)
        )
      end
    end

    def_text create_text, change do
      t("settings.desc", {last_change: change})
    end

    SELECTED   = "■"
    UNSELECTED = "□"

    def create_markup(group_id)
      toggle_btn = ->(text : String, name : String) {
        Button.new(text: text, callback_data: "Settings:#{name}:toggle")
      }
      make_status = ->(name : String) {
        case name
        when "enable_examine"
          KVStore.enabled_examine?(group_id) ? SELECTED : UNSELECTED
        when "trust_admin"
          KVStore.enabled_trust_admin?(group_id) ? SELECTED : UNSELECTED
        when "privacy_setting"
          KVStore.enabled_privacy_setting?(group_id) ? SELECTED : UNSELECTED
        when "record_mode"
          KVStore.enabled_record_mode?(group_id) ? SELECTED : UNSELECTED
        when "fault_tolerance"
          KVStore.enabled_fault_tolerance?(group_id) ? SELECTED : UNSELECTED
        else
          UNSELECTED
        end
      }

      markup = Markup.new
      markup << def_toggle "enable_examine"
      markup << def_toggle "trust_admin"
      markup << def_toggle "privacy_setting"
      markup << def_toggle "record_mode"
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
