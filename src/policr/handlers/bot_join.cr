module Policr
  handler BotJoin do
    match do
      all_pass? [
        KVStore.enabled_examine?(msg.chat.id),
        msg.new_chat_members,
        !Model::Subfunction.disabled?(msg.chat.id, SubfunctionType::BotJoin), # 未关闭子功能
      ]
    end

    handle do
      chat_id = msg.chat.id

      if members = msg.new_chat_members
        members.select { |m| m.is_bot }.select { |m| m.id != bot.self_id }.each do |member|
          conflict_check = ->{
            if INCOMPATIBLE_BOTS.includes? member.id
              midcall SelfJoinHandler do
                _handler.conflict_warning msg.chat.id, member.id
              end
            end
          }
          # 管理员拉入，放行
          if (user = msg.from) && bot.is_admin?(msg.chat.id, user.id)
            if (sended_msg = bot.reply(msg, t("add_from_admin"))) && (message_id = sended_msg.message_id)
              Schedule.after(5.seconds) { bot.delete_message(chat_id, message_id) } unless KVStore.enabled_record_mode?(chat_id)
              # 删除入群消息
              Model::AntiMessage.working chat_id, ServiceMessage::JoinGroup do
                bot.delete_message(chat_id, msg.message_id)
              end
              # 检测冲突
              conflict_check.call
            end
            return
          end
          # 限制机器人
          spawn restrict_bot(msg, member)
          # 检测冲突
          conflict_check.call
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
