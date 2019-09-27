module Policr
  callbacker GlobalBlockRule do
    alias BlockRule = Model::BlockRule

    def handle(query, msg, data)
      chat_id = msg.chat.id
      msg_id = msg.message_id

      user_id = query.from.id

      action = data[0]

      unless user_id == bot.owner_id.to_i # 非管理员操作
        bot.answer_callback_query(query.id, text: t("callback.no_permission"), show_alert: true)
        return
      end

      case action
      when "refresh"
        Cache.carving_global_rules_msg bot.owner_id, msg_id
        updated_text, updated_makrup = update_preview_settings

        async_response

        bot.edit_message_text(
          chat_id,
          message_id: msg_id,
          text: updated_text,
          reply_markup: updated_makrup
        )
      else
        invalid_keyboard
      end
    end

    def update_preview_settings
      midcall PrivateChatHandler do
        {
          _handler.create_global_rules_text,
          _handler.create_global_rules_markup,
        }
      end || {nil, nil}
    end
  end
end
