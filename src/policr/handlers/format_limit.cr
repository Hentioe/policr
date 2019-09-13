module Policr
  handler FormatLimit do
    match do
      chat_id = msg.chat.id
      role = KVStore.enabled_trust_admin?(chat_id) ? :admin : :creator
      self_left = read_state :self_left { false }

      all_pass? [
        !self_left,
        from_group_chat?(msg),
        (document = msg.document),
        (file_name = document.file_name),
        format_inclues?(chat_id, file_name), # 包含在限制格式中？
        (user = msg.from),
        !bot.has_permission?(chat_id, user.id, role),
      ]
    end

    handle do
      chat_id = msg.chat.id
      msg_id = msg.message_id

      bot.delete_message(chat_id, msg_id)
    end

    def format_inclues?(chat_id, file_name)
      extname = File.extname file_name
      extname = extname.gsub(/^\./, "")
      Model::FormatLimit.includes?(chat_id, extname)
    end
  end
end
