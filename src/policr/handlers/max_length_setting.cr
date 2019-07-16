module Policr
  class MaxLengthSettingHandler < Handler
    @reply_msg_id : Int32?

    allow_edit

    def match(msg)
      role = KVStore.trust_admin?(msg.chat.id) ? :admin : :creator

      all_pass? [
        (user = msg.from),
        (reply_msg = msg.reply_to_message),
        (@reply_msg_id = reply_msg.message_id),
        Cache.max_length_msg?(msg.chat.id, @reply_msg_id), # 回复目标为设置长度限制？
        bot.has_permission?(msg.chat.id, user.id, role),
      ]
    end

    def handle(msg)
      if (text = msg.text) && (reply_msg_id = @reply_msg_id)
        chat_id = msg.chat.id

        splits = text.split(" ")
        total, rows =
          if splits.size == 2
            {splits[0].to_i, splits[1].to_i}
          elsif splits.size == 1
            size = splits[0].to_i
            is_rows = size < 50
            {is_rows ? nil : size, is_rows ? size : nil}
          else
            {nil, nil}
          end

        Model::MaxLength.update_total(chat_id, total)
        Model::MaxLength.update_rows(chat_id, rows)

        update_text, update_markup = update_preview_settings(chat_id)
        spawn { bot.edit_message_text(
          chat_id,
          message_id: reply_msg_id,
          text: update_text,
          reply_markup: update_markup
        ) }

        setting_complete_with_delay_delete msg
      end
    end

    def update_preview_settings(chat_id)
      midcall StrictModeCallback do
        {_callback.create_max_length_text(chat_id),
         _callback.create_max_length_markup(chat_id)}
      end || {nil, nil}
    end
  end
end
