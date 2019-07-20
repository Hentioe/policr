module Policr
  class SettingsCallback < Callback
    NOT_MODIFIED = "Bad Request: message is not modified: specified new message content and reply markup are exactly the same as a current content and reply markup of the message"

    def initialize(bot)
      super(bot, "Settings")
    end

    def handle(query, msg, data)
      target_group do
        name = data[0]

        case name
        when "enable_examine"
          selected = KVStore.enabled_examine?(_group_id)
          selected ? KVStore.disable_examine(_group_id) : KVStore.enable_examine(_group_id)
          text = t "settings.desc", {last_change: def_change}
          spawn bot.answer_callback_query(query.id)
          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: text,
            reply_markup: create_markup(_group_id)
          )
        when "trust_admin"
          selected = KVStore.enabled_trust_admin?(_group_id)
          selected ? KVStore.disable_trust_admin(_group_id) : KVStore.enable_trust_admin(_group_id)
          text = t "settings.desc", {last_change: def_change}
          spawn bot.answer_callback_query(query.id)
          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: text,
            reply_markup: create_markup(_group_id)
          )
        when "privacy_setting"
          selected = KVStore.enabled_privacy_setting?(_group_id)
          selected ? KVStore.disable_privacy_setting(_group_id) : KVStore.enable_privacy_setting(_group_id)
          text = t "settings.desc", {last_change: def_change}
          spawn bot.answer_callback_query(query.id)
          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: text,
            reply_markup: create_markup(_group_id)
          )
        when "record_mode"
          selected = KVStore.enabled_record_mode?(_group_id)
          selected ? KVStore.disable_record_mode(_group_id) : KVStore.enable_record_mode(_group_id)
          text = t "settings.desc", {last_change: def_change}
          spawn bot.answer_callback_query(query.id)
          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: text,
            reply_markup: create_markup(_group_id)
          )
        when "enable_from"
          unless KVStore.get_from(_group_id)
            bot.answer_callback_query(query.id, text: t("settings.not_from"), show_alert: true)
            return
          end
          selected = KVStore.enabled_from?(_group_id)
          selected ? KVStore.disable_from(_group_id) : KVStore.enable_from(_group_id)
          text = t "settings.desc", {last_change: def_change}
          spawn bot.answer_callback_query(query.id)
          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: text,
            reply_markup: create_markup(_group_id)
          )
        when "fault_tolerance"
          selected = KVStore.enabled_fault_tolerance?(_group_id)

          if !selected && !(KVStore.enabled_dynamic_captcha?(_group_id) ||
             KVStore.enabled_image_captcha?(_group_id) ||
             KVStore.enabled_chessboard_captcha?(_group_id))
            bot.answer_callback_query(query.id, text: t("settings.fault_tolerance_not_supported"), show_alert: true)
            return
          end

          selected ? KVStore.disable_fault_tolerance(_group_id) : KVStore.enable_fault_tolerance(_group_id)
          text = t "settings.desc", {last_change: def_change}
          spawn bot.answer_callback_query(query.id)
          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: text,
            reply_markup: create_markup(_group_id)
          )
        else # 失效键盘
          bot.answer_callback_query(query.id, text: t("invalid_callback"), show_alert: true)
        end
      end
    end

    macro def_change
      (selected ? t("settings.unselected") : t("settings.selected")) + t("settings.#{name}")
    end

    def create_markup(group_id)
      midcall SettingsCommander do
        commander.create_markup(group_id)
      end
    end
  end
end
