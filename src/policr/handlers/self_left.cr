module Policr
  handler SelfLeft do
    match do
      all_pass? [
        (user = msg.left_chat_member), # 离开聊天？
        bot.self_id == user.id,        # Bot 自己？
      ]
    end

    handle do
      fetch_state :self_left { true }
      chat_id = msg.chat.id
      # 从群组列表缓存中移除
      Cache.delete_group_carving chat_id
      # 更新受管状态
      Model::Group.cancel_manage chat_id
    end
  end
end
