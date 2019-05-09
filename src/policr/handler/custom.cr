module Policr
  class CustomHandler < Handler
    def match(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator

      all_pass? [
        msg.text,
        (user = msg.from),
        (reply_msg = msg.reply_to_message),
        (reply_msg_id = reply_msg.message_id),
        Cache.custom_msg?(reply_msg_id), # 回复目标为定制问题指令？
        bot.has_permission?(msg.chat.id, user.id, role),
      ]
    end

    def handle(msg)
      bot.log "Custom verification for chat_id '#{msg.chat.id}'"
      if (text = msg.text) && !valid?(text) # 内容不合法？
        bot.reply msg, "不合法的格式。注意至少需要存在一个正确（即前缀+的行）答案。"
        return
      end
      DB.custom_text(msg.chat.id, msg.text)
      bot.reply msg, "已完成设置。"
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
