module Policr
  class ReportCommander < Commander
    def initialize(bot)
      super(bot, "report")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role) && (reply_msg = msg.reply_to_message) && (target_user = reply_msg.from)
        # 进行封禁
        # 实现中……

        # 创建举报原因内联键盘
        markup = Markup.new
        target_user_id = target_user.id
        target_msg_id = reply_msg.message_id
        btn = ->(text : String, reason : String) {
          Button.new(text: text, callback_data: "Report:#{target_user_id}:#{target_msg_id}:#{reason}")
        }

        markup << [btn.call(t("report.mass_ad"), "mass_ad")]
        markup << [btn.call(t("report.unident_halal"), "unident_halal")]
        text = t "report.reply_message"
        bot.send_message(msg.chat.id, text: text, reply_to_message_id: reply_msg.message_id, reply_markup: markup)
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end
  end
end
