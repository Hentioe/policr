module Policr
  handler UnverifiedMessage do
    @status : VerificationStatus?

    match do

      all_pass? [
        from_group_chat?(msg),
        !msg.new_chat_members,
        (user = msg.from),
        (status = Cache.verification?(msg.chat.id, user.id)),
        status == VerificationStatus::Init,
      ]
    end

    handle do
      bot.delete_message(msg.chat.id, msg.message_id)
    end
  end
end
