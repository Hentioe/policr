module Policr
  handler PrivateChat do
    match do
      all_pass? [
        from_private_chat?(msg),
        !msg.forward_date, # 非转发消息
        !read_state :done { false },
      ]
    end

    handle do
      msg_id = msg.message_id
      chat_id = msg.chat.id

      if sended_msg = bot.forward_message(
           chat_id: bot.owner_id,
           from_chat_id: msg.chat.id,
           message_id: msg.message_id
         )
        Cache.carving_private_chat_msg "", sended_msg.message_id, {chat_id, msg_id}
      end
    end
  end
end
