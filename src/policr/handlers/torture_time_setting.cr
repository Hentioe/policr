module Policr
  MIN_TORTURE_SEC = 30

  class TortureTimeSettingHandler < Handler
    def match(msg)
      role = KVStore.trust_admin?(msg.chat.id) ? :admin : :creator

      all_pass? [
        (user = msg.from),
        (text = msg.text),
        (reply_msg = msg.reply_to_message),
        (reply_msg_id = reply_msg.message_id),
        Cache.torture_time_msg?(msg.chat.id, reply_msg_id), # 回复验证时间？
        bot.has_permission?(msg.chat.id, user.id, role),
      ]
    end

    def handle(msg)
      sec =
        if text = msg.text
          text.to_i
        else
          DEFAULT_TORTURE_SEC
        end
      if sec > 0 && sec < MIN_TORTURE_SEC # 时间不合法
        bot.reply msg, t("torture.time_too_short", {min_sec: MIN_TORTURE_SEC})
      else
        KVStore.set_torture_sec(msg.chat.id, sec)
        bot.reply msg, t("setting_complete")
      end
    end
  end
end
