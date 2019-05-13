module Policr
  class TortureSecCommander < Commander
    def initialize(bot)
      super(bot, "torture_sec")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        current = t "torture.default", {seconds: DEFAULT_TORTURE_SEC}
        if sec = DB.get_torture_sec(msg.chat.id, -1)
          current = t("torture.exists_set", {seconds: sec}) if sec != -1
        end

        text = t "torture.sec_reply", {current_state: current}
        if send_message = bot.reply msg, text
          Cache.carving_torture_time_msg_sec(send_message.message_id)
        end
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end
  end
end
