module Policr
  class UnverifiedMessage < Handler
    alias VerifyStatus = Cache::VerifyStatus

    @status : (Nil | VerifyStatus)

    def match(msg)
      if user = msg.from
        @status = Cache.verify?(user.id)
      end
    end

    def handle(msg)
      bot.delete_message(msg.chat.id, msg.message_id) if @status == VerifyStatus::Init
    end
  end
end
