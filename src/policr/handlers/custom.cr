module Policr
  handler Custom do
    allow_edit # 处理编辑消息
    target :fields

    match do
      target :group do
        role = KVStore.enabled_trust_admin?(_group_id) ? :admin : :creator

        all_pass? [
          (@reply_msg_id = _reply_msg_id),
          Cache.custom_setting_msg?(msg.chat.id, @reply_msg_id), # 回复目标为设置自定义问题消息？
          msg.text,
          (user = msg.from),
          bot.has_permission?(_group_id, user.id, role),
        ]
      end
    end

    handle do
      retrieve [(text = msg.text)] do
        chat_id = msg.chat.id
        if valid?(text) # 内容合法？

          KVStore.custom_text(_group_id, text)

          updated_text, updated_markup = updated_preview_settings(_group_id, _group_name)

          spawn { bot.edit_message_text(
            chat_id,
            message_id: _reply_msg_id,
            text: updated_text,
            reply_markup: updated_markup
          ) }

          setting_complete_with_delay_delete msg
        else
          bot.reply msg, t("custom.wrong_format")
        end
      end
    end

    def updated_preview_settings(group_id, group_name)
      midcall CustomCommander do
        {_commander.custom_text(group_id, group_name), _commander.create_markup(group_id)}
      end || {nil, nil}
    end

    # 校验设置的合法性
    def valid?(text)
      lines = text.split("\n").map { |line| line.strip }.select { |line| line != "" }
      return false if lines.size < 2
      valid_lines? lines
    end

    private def valid_lines?(lines, index = 1, include_true = false)
      if index < lines.size && (cur = lines[index]) && (cur.starts_with?("-") || cur.starts_with?("+"))
        include_true = cur.starts_with?("+") unless include_true
        valid_lines?(lines, index + 1, include_true)
      else
        include_true
      end
    end
  end
end
