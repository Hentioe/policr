module Policr
  class WelcomeCallback < Callback
    def initialize(bot)
      super(bot, "Welcome")
    end

    def handle(query, msg, data)
      chat_id = msg.chat.id
      from_user_id = query.from.id
      name = data[0]

      # 检测权限
      role = KVStore.trust_admin?(msg.chat.id) ? :admin : :creator
      unless (user = msg.from) && bot.has_permission?(msg.chat.id, from_user_id, role)
        bot.answer_callback_query(query.id, text: t("callback.no_permission"), show_alert: true)
        return
      end

      case name
      when "disable_link_preview"
        is_disable = KVStore.disabled_welcome_link_preview? chat_id
        is_disable ? KVStore.enable_welcome_link_preview(chat_id) : KVStore.disable_welcome_link_preview(chat_id)

        updated_text, updated_markup = updated_settings_preview chat_id

        bot.edit_message_text(
          chat_id,
          message_id: msg.message_id,
          text: updated_text,
          reply_markup: updated_markup
        )
      else # 失效键盘
        bot.answer_callback_query(query.id, text: t("invalid_callback"), show_alert: true)
      end
    end

    def updated_settings_preview(chat_id)
      midcall WelcomeCommander do
        {_commander.text(chat_id), _commander.markup(chat_id)}
      end || {nil, nil}
    end
  end
end
