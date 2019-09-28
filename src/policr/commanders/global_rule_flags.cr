module Policr
  commander GlobalRuleFlags do
    def handle(msg, from_nav)
      reply_menu do
        create_menu({
          text:         paste_text,
          reply_markup: paste_markup,
        })
      end
    end

    SELECTED   = "■"
    UNSELECTED = "□"

    CHECKED   = "●"
    UNCHECKED = "○"

    def_text do
      t "global_rule_flags.desc"
    end

    def_markup do
      flags = Model::GlobalRuleFlag.fetch_by_chat_id! _group_id

      selected_status = ->(name : String) {
        case name
        when "subscribe"
          flags.enabled ? SELECTED : UNSELECTED
        when "report"
          flags.reported ? SELECTED : UNSELECTED
        else
          UNSELECTED
        end
      }

      checked_status = ->(action : HitAction) {
        flags.action == action.value ? CHECKED : UNCHECKED
      }

      toggle_btn = ->(name : String) {
        text = "#{selected_status.call(name)} #{t("global_rule_flags.#{name}")}"
        Button.new(text: text, callback_data: "GlobalRuleFlags:#{name}")
      }

      switch_btn = ->(name : String, action : HitAction) {
        text = "#{checked_status.call(action)} #{t("global_rule_flags.action.#{name}")}"
        Button.new(text: text, callback_data: "GlobalRuleFlags:#{name}:#{action.value}")
      }

      _markup << [toggle_btn.call("subscribe"), toggle_btn.call("report")]
      _markup << [Button.new(
        text: t("global_rule_flags.action_hint"),
        callback_data: "GlobalRuleFlags:action_hint")]
      _markup << [
        switch_btn.call("delete", HitAction::Delete),
        switch_btn.call("restrict", HitAction::Restrict),
        switch_btn.call("ban", HitAction::Ban),
      ]
    end
  end
end
