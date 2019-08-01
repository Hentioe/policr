module Policr
  class LeftGroupHandler < Handler
    alias AntiTarget = AntiMessageDeleteTarget

    def match(msg)
      all_pass? [
        KVStore.enabled_examine?(msg.chat.id),
        msg.left_chat_member, # 离开聊天？
      ]
    end

    def handle(msg)
      chat_id = msg.chat.id
      # 删除退群消息
      Model::AntiMessage.working chat_id, AntiTarget::LeaveGroup do
        spawn bot.delete_message(chat_id, msg.message_id)
      end
    end
  end
end
