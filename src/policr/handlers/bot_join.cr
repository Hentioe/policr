module Policr
  handler BotJoin do
    alias AntiTarget = AntiMessageDeleteTarget

    def match(msg)
      all_pass? [
        KVStore.enabled_examine?(msg.chat.id),
        msg.new_chat_members,
        !Model::Subfunction.disabled?(msg.chat.id, SubfunctionType::BotJoin), # 未关闭子功能
      ]
    end

    def handle(msg)
      chat_id = msg.chat.id

      if members = msg.new_chat_members
        members.select { |m| m.is_bot }.select { |m| m.id != bot.self_id }.each do |member|
          # 管理员拉入，放行
          if (user = msg.from) && bot.is_admin?(msg.chat.id, user.id)
            if (sended_msg = bot.reply(msg, t("add_from_admin"))) && (message_id = sended_msg.message_id)
              Schedule.after(5.seconds) { bot.delete_message(chat_id, message_id) } unless KVStore.enabled_record_mode?(chat_id)

              # 删除入群消息
              Model::AntiMessage.working chat_id, AntiTarget::JoinGroup do
                bot.delete_message(chat_id, msg.message_id)
              end
            end
            return
          end
          # 限制机器人
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
      bot.send_message(
        msg.chat.id,
        text: t("restrict_bot"),
        reply_to_message_id: msg.message_id,
        reply_markup: markup
      )
      bot.log "Bot '#{bot_member.id}' has been restricted"
    end
  end
end
