module Policr
  class WelcomeCallback < Callback
    def initialize(bot)
      super(bot, "Welcome")
    end

    def handle(query, msg, data)
      target_group do
        name = data[0]

        case name
        when "disable_link_preview"
          is_disable = KVStore.disabled_welcome_link_preview? _group_id
          is_disable ? KVStore.enable_welcome_link_preview(_group_id) : KVStore.disable_welcome_link_preview(_group_id)

          spawn bot.answer_callback_query(query.id)

          updated_text, updated_markup = updated_settings_preview _group_id, _group_name

          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: updated_text,
            reply_markup: updated_markup
          )
        when "welcome"
          unless KVStore.get_welcome(_group_id)
            bot.answer_callback_query(query.id, text: t("welcome.missing_content"), show_alert: true)
            return
          end
          selected = KVStore.enabled_welcome?(_group_id)
          selected ? KVStore.disable_welcome(_group_id) : KVStore.enable_welcome(_group_id)

          spawn bot.answer_callback_query(query.id)

          updated_text, updated_markup = updated_settings_preview _group_id, _group_name

          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: updated_text,
            reply_markup: updated_markup
          )
        else # 失效键盘
          bot.answer_callback_query(query.id, text: t("invalid_callback"), show_alert: true)
        end
      end
    end

    def updated_settings_preview(group_id, group_name)
      midcall WelcomeCommander do
        {_commander.text(group_id, group_name), _commander.markup(group_id)}
      end || {nil, nil}
    end
  end
end
