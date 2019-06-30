module Policr
  class FromSettingHandler < Handler
    def match(msg)
      role = KVStore.trust_admin?(msg.chat.id) ? :admin : :creator

      all_pass? [
        (user = msg.from),
        (reply_msg = msg.reply_to_message),
        (reply_msg_id = reply_msg.message_id),
        Cache.from_setting_msg?(reply_msg_id), # 回复目标为设置来源指令？
        bot.has_permission?(msg.chat.id, user.id, role),
      ]
    end

    def handle(msg)
      bot.log "Enable From Investigate for ChatID '#{msg.chat.id}'"
      KVStore.put_chat_from(msg.chat.id, msg.text)
      bot.reply msg, t("setting_complete")
    end
  end
end
