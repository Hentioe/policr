module Policr
  class TortureTimeCommander < Commander
    def initialize(bot)
      super(bot, "torture_time")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        if send_message = bot.send_message msg.chat.id, text(msg.chat.id), reply_to_message_id: msg.message_id, disable_web_page_preview: true, parse_mode: "markdown", reply_markup: create_markup
          Cache.carving_torture_time_msg_sec(send_message.message_id)
        end
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end

    def create_markup
      markup = Markup.new
      btn = ->(text : String, sec : Int32 | String) {
        Button.new(text: text, callback_data: "TortureTime:#{sec}")
      }
      markup << [btn.call("30秒", 30), btn.call("55秒", 55), btn.call("80秒", 80), btn.call("100秒", 100)]
      markup << [btn.call("2分钟", 120), btn.call("3分钟", 180), btn.call("5分钟", 300), btn.call("7分钟", 420)]
      markup << [btn.call("无验证倒计时（不推荐）", 0), btn.call("刷新", "refresh")]
      markup
    end

    def text(chat_id)
      current = t "torture.default_set", {seconds: DEFAULT_TORTURE_SEC}
      if sec = DB.get_torture_sec chat_id
        time_len = sec > 0 ? "#{sec} 秒" : "无限"
        current = t("torture.exists_set", {time_len: time_len})
      end
      t "torture.time_setting", {current_state: current}
    end
  end
end
