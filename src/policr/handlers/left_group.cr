module Policr
  class LeftGroupHandler < Handler
    alias DeleteTarget = AntiMessageDeleteTarget

    def match(msg)
      all_pass? [
        KVStore.enabled_examine?(msg.chat.id),
        msg.left_chat_member, # 离开聊天？
      ]
    end

    def handle(msg)
      # 删除退群消息
      unless Model::AntiMessage.disabled?(msg.chat.id, DeleteTarget::LeaveGroup)
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end
  end
end
