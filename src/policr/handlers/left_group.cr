module Policr
  class LeftGroupHandler < Handler
    def match(msg)
      all_pass? [
        KVStore.enable_examine?(msg.chat.id),
        msg.left_chat_member, # 离开聊天？
      ]
    end

    def handle(msg)
      bot.delete_message(msg.chat.id, msg.message_id) unless KVStore.record_mode?(msg.chat.id)
    end
  end
end
