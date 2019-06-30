module Policr
  class ReportCommander < Commander
    def initialize(bot)
      super(bot, "report")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && (bot.has_permission?(msg.chat.id, user.id, role) || user.username == "Hentioe") && (reply_msg = msg.reply_to_message) && (target_user = reply_msg.from)
        author_id = user.id
        target_user_id = target_user.id
        target_msg_id = reply_msg.message_id

        # 创建举报原因内联键盘
        markup = Markup.new
        btn = ->(text : String, reason : ReportReason) {
          Button.new(text: text, callback_data: "Report:#{author_id}:#{target_user_id}:#{target_msg_id}:#{reason.value}")
        }

        markup << [btn.call(t("report.mass_ad"), ReportReason::Spam)]
        markup << [btn.call(t("report.unident_halal"), ReportReason::Halal)]
        text = t "report.admin_reply", {user_id: target_user_id, voting_channel: bot.voting_channel}
        bot.send_message(
          msg.chat.id, text: text,
          reply_to_message_id: msg.message_id,
          reply_markup: markup,
          parse_mode: "markdown",
          disable_web_page_preview: true
        )
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end
  end
end
