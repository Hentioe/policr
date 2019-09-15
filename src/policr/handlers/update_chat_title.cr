module Policr
  handler UpdateChatTitle do
    match do
      all_pass? [
        from_group_chat?(msg),
        msg.new_chat_title, # 新群聊标题？
      ]
    end

    handle do
      if (chat_title = msg.new_chat_title)
        Model::Group.update_title! msg.chat.id, chat_title
      end
    end
  end
end
