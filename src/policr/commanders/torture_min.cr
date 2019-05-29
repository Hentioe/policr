module Policr
  class TortureMinCommander < Commander
    def initialize(bot)
      super(bot, "torture_min")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        current = t "torture.default_set", {seconds: DEFAULT_TORTURE_SEC}
        if sec = DB.get_torture_sec(msg.chat.id)
          time_len = sec > 0 ? "#{sec} 秒" : "无限"
          current = t("torture.exists_set", {time_len: time_len})
        end

        text = t "torture.min_reply", {current_state: current}
        if send_message = bot.reply msg, text
          Cache.carving_torture_time_msg_min(send_message.message_id)
        end
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end
  end
end
