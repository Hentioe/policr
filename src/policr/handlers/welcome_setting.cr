module Policr
  class WelcomeSettingHandler < Handler
    def match(msg)
      role = KVStore.trust_admin?(msg.chat.id) ? :admin : :creator

      all_pass? [
        (user = msg.from),
        (reply_msg = msg.reply_to_message),
        (reply_msg_id = reply_msg.message_id),
        Cache.welcome_setting_msg?(msg.chat.id, reply_msg_id), # 回复目标为设置欢迎消息指令？
        bot.has_permission?(msg.chat.id, user.id, role),
      ]
    end

    def handle(msg)
      bot.log "Setting Welcome for group '#{msg.chat.id}'"
      KVStore.set_welcome(msg.chat.id, msg.text)
      bot.reply msg, t("setting_complete")
    end
  end
end
