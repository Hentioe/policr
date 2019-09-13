module Policr
  handler LeftGroup do
    match do
      # 从群组列表缓存中移除
      all_pass? [
        KVStore.enabled_examine?(msg.chat.id),
        (user = msg.left_chat_member), # 离开聊天？
        bot.self_id != user.id,        # 消息发送者非 Bot 自身
      ]
    end

    handle do
      if (user = msg.left_chat_member) && (user_id = user.id)
        chat_id = msg.chat.id
        # 删除退群消息
        Model::AntiMessage.working chat_id, ServiceMessage::LeaveGroup do
          spawn bot.delete_message(chat_id, msg.message_id)
        end
        # 立即执行可能存在的验证任务
        spawn {
          before = ->{ Cache.verification_left chat_id, user_id }
          after = ->{ Cache.verification_status_clear chat_id, user_id }
          Policr.schedule_immediately("#{chat_id}_#{user_id}", before, after, delete: false)
        }
      end
    end
  end
end
