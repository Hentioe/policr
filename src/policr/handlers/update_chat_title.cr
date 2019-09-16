module Policr
  handler UpdateChatTitle do
    match do
      all_pass? [
        from_group_chat?(msg),
        msg.new_chat_title, # 新群聊标题？
      ]
    end

    handle do
      chat_id = msg.chat.id
      msg_id = msg.message_id

      Model::AntiMessage.working chat_id, ServiceMessage::DataChange do
        spawn bot.delete_message(chat_id, msg_id)
      end if examine_enabled?

      if (chat_title = msg.new_chat_title)
        Model::Group.update_title! chat_id, chat_title
      end
    end
  end
end
