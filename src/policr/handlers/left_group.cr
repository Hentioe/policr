module Policr
  handler LeftGroup do
    match do
      all_pass? [
        (user = msg.left_chat_member), # 离开聊天？
        examine_enabled?,
        bot.self_id != user.id, # 消息发送者非 Bot 自身
      ]
    end

    handle do
      if (user = msg.left_chat_member) && (user_id = user.id)
        chat_id = msg.chat.id
        # 删除退群消息
        Model::AntiMessage.working chat_id, ServiceMessage::LeaveGroup do
          spawn bot.delete_message(chat_id, msg.message_id)
        end
        unless Cache.verification?(chat_id, user_id) == VerificationStatus::Wrong # 上一条状态非验证错误
          # 立即执行可能存在的验证任务
          spawn {
            # 将验证状态置为离开，用于立即删除验证消息
            before = ->{ Cache.verification_left chat_id, user_id }
            # 清空验证状态
            after = ->{ Cache.verification_status_clear chat_id, user_id }
            Policr.schedule_immediately("#{chat_id}_#{user_id}", before, after, delete: false)
          }
        end
      end
    end
  end
end
