module Policr
  class JoinBotHandler < Handler
    alias VerifyStatus = Cache::VerifyStatus

    @members = Array(TelegramBot::User).new

    def match(msg)
      if (members = msg.new_chat_members) && DB.enable_examine?(msg.chat.id)
        @members = members
      end
    end

    def handle(msg)
      @members.select { |m| m.is_bot }.each do |member|
        bot.restrict_bot(msg, member)
      end
    end
  end
end
