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
        bot.reply msg, t("custom.wrong_format")
        return
      end
      DB.custom_text(msg.chat.id, msg.text)
      bot.reply msg, t("setting_complete")
      # 更新回复消息内联键盘
      if reply_msg = msg.reply_to_message
        text = t("custom.desc")
        bot.edit_message_text chat_id: msg.chat.id, message_id: reply_msg.message_id, text: text, disable_web_page_preview: true, parse_mode: "markdown", reply_markup: create_markup(msg.chat.id)
      end
    end

    def create_markup(chat_id)
      if (commander = bot.commanders[:custom]?) && (commander.is_a?(CustomCommander))
        commander.create_markup(chat_id)
      else
        Markup.new
      end
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
