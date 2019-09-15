module Policr
  handler UpdateChatPhoto do
    match do
      all_pass? [
        from_group_chat?(msg),
        msg.new_chat_photo, # 新群聊头像？
      ]
    end

    handle do
      chat_id = msg.chat.id
      msg_id = msg.message_id

      Model::AntiMessage.working chat_id, ServiceMessage::DataChange do
        spawn bot.delete_message(chat_id, msg_id)
      end if KVStore.enabled_examine?(chat_id)
    end
  end
end
