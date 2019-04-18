module Policr
  class TortureMinCommander < Commander
    def initialize(bot)
      super(bot, "torture_min")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        current = "此群组当前使用 Bot 默认的时长（#{DEFAULT_TORTURE_SEC} 秒）"
        if sec = DB.get_torture_sec(msg.chat.id, -1)
          current = "此群组当前已设置时长（#{sec} 秒）" if sec != -1
        end

        text = "欢迎设置入群验证的等待时间，#{current}。请使用有效的数字作为分钟数回复此消息以设置或更新独立的验证时间，支持小数。注意：此消息可能因为机器人的重启而失效，请即时回复。"
        if send_message = bot.reply msg, text
          Cache.carving_torture_time_msg_min(send_message.message_id)
        end
      end
    end
  end
end
