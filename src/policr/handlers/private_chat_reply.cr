module Policr
  handler PrivateChatReply do
    allow_edit

    @chat_info : {Int64, Int32}?

    match do
      all_pass? [
        from_private_chat?(msg),
        (reply_msg = msg.reply_to_message),
        (@chat_info = Cache.private_chat_msg?("", reply_msg.message_id)), # 针对无关私聊的回复？
        msg.text,
      ]
    end

    handle do
      if (text = msg.text) && (chat_info = @chat_info)
        user_id, reply_to_msg_id = chat_info

        bot.send_message(
          user_id,
          text: text,
          reply_to_message_id: reply_to_msg_id
        )
      end
    end
  end
end
