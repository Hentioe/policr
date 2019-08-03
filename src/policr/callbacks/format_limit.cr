module Policr
  callbacker FormatLimit do
    def handle(query, msg, data)
      target_group do
        extension_name, toggle = data
        msg_id = msg.message_id

        unless toggle == "toggle" # 失效键盘
          bot.answer_callback_query(query.id, text: t("invalid_callback"), show_alert: true)
          return
        end

        if Model::FormatLimit.includes?(_group_id, extension_name)
          Model::FormatLimit.delete_format(_group_id, extension_name)
        else
          Model::FormatLimit.put_list!(_group_id, [extension_name])
        end

        spawn bot.answer_callback_query(query.id)

        updated_text, updated_markup = updated_preview_settings(_group_id, _group_name)
        bot.edit_message_text(
          _chat_id,
          message_id: msg_id,
          text: updated_text,
          reply_markup: updated_markup
        )
      end
    end

    def updated_preview_settings(group_id, group_name)
      midcall StrictModeCallback do
        {
          _callback.create_format_limit_text(group_id, group_name),
          _callback.create_format_limit_markup(group_id),
        }
      end || {nil, nil}
    end
  end
end
