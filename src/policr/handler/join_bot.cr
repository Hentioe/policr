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
        restrict_bot(msg, member)
      end
    end

    def restrict_bot(msg, bot_member)
      bot.restrict_chat_member(msg.chat.id, bot_member.id, can_send_messages: false)

      btn = ->(text : String, chooese_id : Int32) {
        Button.new(text: text, callback_data: "BotJoin:#{bot_member.id}:[none]:#{chooese_id}")
      }
      markup = Markup.new
      markup << [btn.call("解除限制", 0), btn.call("直接移除", -1)]
      bot.send_message(msg.chat.id, "抓到一个新加入的机器人，安全考虑已对其进行限制。如有需要可自行解除，否则请移除。", reply_to_message_id: msg.message_id, reply_markup: markup)
      bot.log "Bot '#{bot_member.id}' has been restricted"
    end
  end
end
