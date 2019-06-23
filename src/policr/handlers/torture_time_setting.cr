module Policr
  MIN_TORTURE_SEC = 30

  class TortureTimeSettingHandler < Handler
    @time_type : TortureTimeType?
    @text : String?

    def match(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator

      if all_pass? [
           (user = msg.from),
           (text = msg.text),
           (reply_msg = msg.reply_to_message),
           (reply_msg_id = reply_msg.message_id),
           (time_type = Cache.torture_time_msg?(reply_msg_id)), # 验证时间？
           bot.has_permission?(msg.chat.id, user.id, role),
         ]
        @time_type = time_type
        @text = text
      end
    end

    def handle(msg)
      if (time_type = @time_type) && (text = @text)
        sec = case time_type
              when TortureTimeType::Sec
                text.to_i
              when TortureTimeType::Min
                (60 * (text.to_f)).to_i
              else
                DEFAULT_TORTURE_SEC
              end
        if sec > 0 && sec < MIN_TORTURE_SEC # 时间不合法
          bot.reply msg, t("torture.time_too_short", {min_sec: MIN_TORTURE_SEC})
        else
          DB.set_torture_sec(msg.chat.id, sec)
          bot.reply msg, t("setting_complete")
        end
      end
    end
  end
end
