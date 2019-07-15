module Policr
  class UnverifiedMessageHandler < Handler
    @status : VerificationStatus?

    def match(msg)
      if (!msg.new_chat_members) && (user = msg.from)
        @status = Cache.verification?(msg.chat.id, user.id)
      end
    end

    def handle(msg)
      bot.delete_message(msg.chat.id, msg.message_id) if @status == VerificationStatus::Init
    end
  end
end
