module Policr
  class HalalMessageHandler < Handler
    ARABIC_CHARACTERS = /^[\x{0600}-\x{06FF}-\x{0750}-\x{077F}-\x{08A0}-\x{08FF}-\x{FB50}-\x{FDFF}-\x{FE70}-\x{FEFF}-\x{10E60}-\x{10E7F}-\x{1EC70}-\x{1ECBF}-\x{1ED00}-\x{1ED4F}-\x{1EE00}-\x{1EEFF} ]+$/
    SAFE_MSG_SIZE     = 2 # 消息的安全长度

    def match(msg)
      all_pass? [
        DB.enable_examine?(msg.chat.id),
        msg.from,
        (text = msg.text),
        text.size > SAFE_MSG_SIZE, # 大于安全长度
        text =~ ARABIC_CHARACTERS, # 全文匹配阿拉伯字符
      ]
    end

    def handle(msg)
      if (user = msg.from)
        kick_halal_with_receipt(msg, user)
      end
    end

    def kick_halal_with_receipt(msg, member)
      name = bot.get_fullname(member)
      bot.log "Found a halal '#{name}'"
      if DB.halal_white? member.id
        bot.log "Halal '#{name}' in whitelist, ignored"
        return
      end
      text = t("halal.found")
      sended_msg = bot.reply msg, text

      if sended_msg && (join_user_handler = bot.handlers[:join_user]?) && join_user_handler.is_a?(JoinUserHandler)
        begin
          bot.kick_chat_member(msg.chat.id, member.id)
          member_id = member.id
          text = t("halal.ban")
          bot.edit_message_text(chat_id: sended_msg.chat.id, message_id: sended_msg.message_id,
            text: text, reply_markup: join_user_handler.add_banned_menu(member_id, member.username, true))
          bot.log "Halal '#{name}' has been banned"
        rescue ex : TelegramBot::APIException
          text = t("halal.ban_failure")
          bot.edit_message_text(chat_id: sended_msg.chat.id, message_id: sended_msg.message_id,
            text: text)
          _, reason = bot.get_error_code_with_reason(ex)
          bot.log "Halal '#{name}' banned failure, reason: #{reason}"
        end
      end
    end
  end
end
