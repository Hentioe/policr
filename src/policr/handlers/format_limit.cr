module Policr
  handler FormatLimit do
    match do
      chat_id = msg.chat.id

      all_pass? [
        !self_left?,
        !deleted?,
        examine_enabled?,
        from_group_chat?(msg),
        (document = msg.document),
        (file_name = document.file_name),
        format_inclues?(chat_id, file_name), # 包含在限制格式中？
        (user = msg.from),
        !has_permission?(chat_id, user.id),
      ]
    end

    handle do
      chat_id = msg.chat.id
      msg_id = msg.message_id

      spawn bot.delete_message(chat_id, msg_id)

      deleted # 标记删除
    end

    def format_inclues?(chat_id, file_name)
      extname = File.extname file_name
      extname = extname.gsub(/^\./, "")
      Model::FormatLimit.includes?(chat_id, extname)
    end
  end
end
