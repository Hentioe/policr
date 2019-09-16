module Policr
  handler PinnedMessage do
    match do
      all_pass? [
        from_group_chat?(msg),
        examine_enabled?,
        msg.pinned_message, # 置顶消息？
      ]
    end

    handle do
      chat_id = msg.chat.id
      msg_id = msg.message_id

      Model::AntiMessage.working chat_id, ServiceMessage::PinnedMessage do
        spawn bot.delete_message(chat_id, msg_id)
      end
    end
  end
end
