module Policr
  class MaxLengthSettingHandler < Handler
    allow_edit
    target :fields

    def match(msg)
      target :group do
        role = KVStore.enabled_trust_admin?(_group_id) ? :admin : :creator

        all_pass? [
          msg.text,
          (user = msg.from),
          bot.has_permission?(_group_id, user.id, role),
          (@reply_msg_id = _reply_msg_id),
          Cache.max_length_msg?(msg.chat.id, @reply_msg_id), # 回复目标为设置长度限制？
        ]
      end
    end

    def handle(msg)
      retrieve [(text = msg.text)] do
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

        Model::MaxLength.update_total(_group_id, total)
        Model::MaxLength.update_rows(_group_id, rows)

        update_text, update_markup = update_preview_settings(_group_id, _group_name)
        spawn { bot.edit_message_text(
          chat_id,
          message_id: _reply_msg_id,
          text: update_text,
          reply_markup: update_markup
        ) }

        setting_complete_with_delay_delete msg
      end
    end

    def update_preview_settings(group_id, group_name)
      midcall StrictModeCallback do
        {_callback.create_max_length_text(group_id, group_name),
         _callback.create_max_length_markup(group_id)}
      end || {nil, nil}
    end
  end
end
