module Policr
  handler PrivateChat do
    match do
      !read_state :done { false }
      all_pass? [
        from_private_chat?(msg),
        !read_state :done { false },
        msg.text,
      ]
    end

    handle do
      bot.forward_message(
        chat_id: 340396281,
        from_chat_id: msg.chat.id,
        message_id: msg.message_id
      )
    end
  end
end
