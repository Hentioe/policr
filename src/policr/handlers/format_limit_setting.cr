module Policr
  handler FormatLimitSetting do
    allow_edit
    target :fields

    def match(msg)
      target :group do
        role = KVStore.enabled_trust_admin?(_group_id) ? :admin : :creator

        all_pass? [
          msg.text,
          (@reply_msg_id = _reply_msg_id),
          Cache.format_limit_msg?(msg.chat.id, @reply_msg_id), # 回复目标为设置屏蔽文件格式？
          (user = msg.from),
          bot.has_permission?(_group_id, user.id, role),
        ]
      end
    end

    def handle(msg)
      retrieve [(text = msg.text)] do
        chat_id = msg.chat.id

        list = text.split(" ")
        Model::FormatLimit.put_list!(_group_id, list)

        updated_text, updated_markup = updated_preview_settings(_group_id, _group_name)
        spawn { bot.edit_message_text(
          chat_id,
          message_id: _reply_msg_id,
          text: updated_text,
          reply_markup: updated_markup
        ) }

        setting_complete_with_delay_delete msg
      end
    end

    def updated_preview_settings(group_id, group_name)
      midcall StrictModeCallback do
        {_callback.create_format_limit_text(group_id, group_name),
         _callback.create_format_limit_markup(group_id)}
      end || {nil, nil}
    end
  end
end
