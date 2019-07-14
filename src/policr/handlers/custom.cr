module Policr
  class CustomHandler < Handler
    allow_edit # 处理编辑消息

    def match(msg)
      role = KVStore.trust_admin?(msg.chat.id) ? :admin : :creator

      all_pass? [
        msg.text,
        (user = msg.from),
        (reply_msg = msg.reply_to_message),
        (reply_msg_id = reply_msg.message_id),
        Cache.custom_setting_msg?(msg.chat.id, reply_msg_id), # 回复目标为定制问题指令？
        bot.has_permission?(msg.chat.id, user.id, role),
      ]
    end

    def handle(msg)
      bot.log "Custom verification for chat_id '#{msg.chat.id}'"
      if (text = msg.text) && !valid?(text) # 内容不合法？
        bot.reply msg, t("custom.wrong_format")
        return
      end

      chat_id = msg.chat.id

      KVStore.custom_text(msg.chat.id, msg.text)

      # 更新回复消息内联键盘
      if reply_msg = msg.reply_to_message
        updated_text, updated_markup = updated_preview_settings(chat_id)
        reply_msg_id = reply_msg.message_id

        spawn { bot.edit_message_text(
          chat_id: msg.chat.id, message_id: reply_msg_id, text: updated_text,
          disable_web_page_preview: true, parse_mode: "markdown", reply_markup: updated_markup
        ) }
      end

      setting_complete_with_delay_delete msg
    end

    def updated_preview_settings(chat_id)
      midcall CustomCommander do
        {_commander.custom_text(chat_id), _commander.create_markup(chat_id)}
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
