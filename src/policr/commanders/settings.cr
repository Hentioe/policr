module Policr
  commander Settings do
    alias Toggle = Model::Toggle

    def handle(msg, from_nav)
      reply_menu do
        create_menu({
          text:         create_text(_group_id, t("settings.none"), _group_name),
          reply_markup: create_markup(_group_id, from_nav: from_nav),
        })
      end
    end

    def_text create_text, change do
      t("settings.desc", {last_change: change})
    end

    SELECTED   = "■"
    UNSELECTED = "□"

    def_markup do
      toggle_btn = ->(text : String, name : String) {
        Button.new(text: text, callback_data: "Settings:#{name}:toggle")
      }
      make_status = ->(name : String) {
        case name
        when "enable_examine"
          Toggle.examine_enabled?(_group_id) ? SELECTED : UNSELECTED
        when "trust_admin"
          KVStore.enabled_trust_admin?(_group_id) ? SELECTED : UNSELECTED
        when "privacy_setting"
          KVStore.enabled_privacy_setting?(_group_id) ? SELECTED : UNSELECTED
        when "record_mode"
          KVStore.enabled_record_mode?(_group_id) ? SELECTED : UNSELECTED
        when "fault_tolerance"
          KVStore.enabled_fault_tolerance?(_group_id) ? SELECTED : UNSELECTED
        when "slient_mode"
          Model::Toggle.enabled?(_group_id, ToggleTarget::SlientMode) ? SELECTED : UNSELECTED
        else
          UNSELECTED
        end
      }

      _markup << def_toggle "enable_examine"
      _markup << def_toggle "trust_admin"
      _markup << def_toggle "privacy_setting"
      _markup << def_toggle "record_mode"
      _markup << def_toggle "fault_tolerance"
      _markup << def_toggle "slient_mode"
    end

    private macro def_toggle(name)
      [
        toggle_btn.call(make_status.call({{name}}) + " " + t("settings.{{name.id}}"), {{name}})
      ]
    end
  end
end
