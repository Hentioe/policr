module Policr
  handler HalalMessage do
    ARABIC_CHARACTERS = /^[\x{0600}-\x{06FF}\x{0750}-\x{077F}\x{08A0}-\x{08FF}\x{FB50}-\x{FDFF}\x{FE70}-\x{FEFF}\x{10E60}-\x{10E7F}\x{1EC70}-\x{1ECBF}\x{1ED00}-\x{1ED4F}\x{1EE00}-\x{1EEFF} ]+$/
    SAFE_MSG_SIZE     = 6 # 消息的安全长度

    ARABIC_CHARACTER = /[\x{0600}-\x{06FF}\x{0750}-\x{077F}\x{08A0}-\x{08FF}\x{FB50}-\x{FDFF}\x{FE70}-\x{FEFF}\x{10E60}-\x{10E7F}\x{1EC70}-\x{1ECBF}\x{1ED00}-\x{1ED4F}\x{1EE00}-\x{1EEFF}]/

    allow_edit # 处理编辑消息

    match do
      self_left = read_state :self_left { false }

      all_pass? [
        !self_left,
        from_group_chat?(msg),
        KVStore.enabled_examine?(msg.chat.id),
        !Model::Subfunction.disabled?(msg.chat.id, SubfunctionType::BanHalal), # 未关闭子功能
        (text = msg.text),
        is_halal(text),
      ]
    end

    handle do
      if (text = msg.text) && (user = msg.from)
        kick_halal(msg, user)
      end
    end

    def is_halal(text)
      len = text.gsub(" ", "").size
      len < SAFE_MSG_SIZE ? full_match(text) : character_ratio(text, len)
    end

    def full_match(text)
      text =~ ARABIC_CHARACTERS
    end

    def character_ratio(text, len)
      i = 0
      text.gsub(ARABIC_CHARACTER) { |_| i += 1 }
      r = i.to_f / len.to_f
      r >= 0.65
    end

    def kick_halal(msg, member)
      name = fullname(member)
      bot.log "Found a halal '#{name}'"

      chat_id = msg.chat.id
      text = t("halal.found")
      sended_msg = bot.reply msg, text

      if sended_msg
        kick_msg_id = sended_msg.message_id
        midcall UserJoinHandler do
          begin
            bot.kick_chat_member(msg.chat.id, member.id)
            member_id = member.id
            text = t "halal.kicked", {user_id: member_id}
            markup = _handler.add_banned_menu(member_id, true)
            bot.edit_message_text(
              chat_id,
              message_id: kick_msg_id,
              text: text,
              reply_markup: markup
            )
            # 延迟清理
            Model::CleanMode.working(chat_id, CleanDeleteTarget::Halal) do
              spawn bot.delete_message(chat_id, kick_msg_id)
              spawn bot.delete_message(chat_id, msg.message_id)
            end
            bot.log "Halal '#{name}' has been banned"
          rescue ex : TelegramBot::APIException
            _, reason = bot.parse_error(ex)
            text = t("halal.kick_failed", {user_id: member.id, reason: reason})
            bot.edit_message_text sended_msg.chat.id, message_id: sended_msg.message_id, text: text
            bot.log "Halal '#{name}' banned failure, reason: #{reason}"
          end
        end
      end
    end
  end
end
