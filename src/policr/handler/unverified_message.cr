module Policr
  class UnverifiedMessageHandler < Handler
    alias VerifyStatus = Cache::VerifyStatus

    @status : (Nil | VerifyStatus)

    def match(msg)
      if (!msg.new_chat_members) && (user = msg.from)
        @status = Cache.verify?(user.id)
      end
    end

    def handle(msg)
      bot.delete_message(msg.chat.id, msg.message_id) if @status == VerifyStatus::Init
    end
  end
end
