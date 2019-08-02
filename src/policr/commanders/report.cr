module Policr
  class ReportCommander < Commander
    alias Reason = ReportReason

    match :report

    def handle(msg)
      if (user = msg.from) && (reply_msg = msg.reply_to_message) && (target_user = reply_msg.from)
        author_id = user.id
        target_user_id = target_user.id
        target_msg_id = reply_msg.message_id
        chat_id = msg.chat.id

        if error_msg = check_legality(author_id, target_user_id)
          bot.send_message chat_id, error_msg, reply_to_message_id: msg.message_id
          return
        end

        # 创建举报原因内联键盘
        markup = Markup.new
        btn = ->(text : String, reason : ReportReason) {
          Button.new(text: text, callback_data: "Report:#{author_id}:#{target_user_id}:#{target_msg_id}:#{reason.value}")
        }

        markup << [btn.call(t("report.mass_ad"), Reason::Spam)]
        markup << [btn.call(t("report.unident_halal"), Reason::Halal)]
        markup << [btn.call(t("report.hateful"), Reason::Hateful)]
        markup << [btn.call(t("report.adname"), Reason::Adname)]

        text = t "report.admin_reply", {user_id: target_user_id, voting_channel: bot.voting_channel}
        bot.send_message(
          msg.chat.id,
          text: text,
          reply_to_message_id: msg.message_id,
          reply_markup: markup
        )
        # 缓存被举报用户
        Cache.carving_report_target_msg chat_id, target_msg_id, target_user
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end

    def check_legality(author_id, target_user_id)
      if author_id == target_user_id # 不能举报自己
        t "report.author_cant_self"
      elsif target_user_id == bot.self_id # 不能举报本机器人
        t "report.target_user_cant_the_bot"
      elsif target_user_id == 777000 # 举报目标用户无效
        t "report.target_user_invalid"
      end
    end
  end
end
