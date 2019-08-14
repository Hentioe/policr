module Policr
  handler UnverifiedMessage do
    @status : VerificationStatus?

    match do
      if (!msg.new_chat_members) && (user = msg.from)
        @status = Cache.verification?(msg.chat.id, user.id)
      end
    end

    handle do
      bot.delete_message(msg.chat.id, msg.message_id) if @status == VerificationStatus::Init
    end
  end
end
