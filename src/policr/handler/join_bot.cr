module Policr
  class JoinBotHandler < Handler
    alias VerifyStatus = Cache::VerifyStatus

    def match(msg)
      all_pass? [
        DB.enable_examine?(msg.chat.id),
        msg.new_chat_members,
      ]
    end

    def handle(msg)
      if members = msg.new_chat_members
        members.select { |m| m.is_bot }.each do |member|
          restrict_bot(msg, member)
        end
      end
    end

    def restrict_bot(msg, bot_member)
      bot.restrict_chat_member(msg.chat.id, bot_member.id, can_send_messages: false)

      btn = ->(text : String, chooese_id : Int32) {
        Button.new(text: text, callback_data: "BotJoin:#{bot_member.id}:[none]:#{chooese_id}")
      }
      markup = Markup.new
      markup << [btn.call(t("restrict_bot_menu.derestrict"), 0), btn.call(t("restrict_bot_menu.remove"), -1)]
      bot.send_message(msg.chat.id, t("restrict_bot"), reply_to_message_id: msg.message_id, reply_markup: markup)
      bot.log "Bot '#{bot_member.id}' has been restricted"
    end
  end
end
