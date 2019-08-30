module Policr
  commander Report do
    alias Reason = ReportReason

    FILE_EXCLUDES = [".gif", ".mp4"]

    def self.is_file?(reply_msg : TelegramBot::Message)
      (doc = reply_msg.document) &&
        (filename = doc.file_name) &&
        !FILE_EXCLUDES.includes?(File.extname(filename))
    end

    def handle(msg, from_nav)
      if (user = msg.from) && (reply_msg = msg.reply_to_message) && (target_user = reply_msg.from)
        author_id = user.id
        target_user_id = target_user.id
        target_msg_id = reply_msg.message_id
        chat_id = msg.chat.id
        msg_id = msg.message_id

        sended_msg =
          if error_msg = check_legality(author_id, target_user_id)
            bot.send_message chat_id, error_msg, reply_to_message_id: msg_id
          elsif link = repeat?(chat_id, target_msg_id)
            bot.send_message chat_id, t("report.repeat_error", {voting_link: link}), reply_to_message_id: msg_id
          else
            # 创建举报原因内联键盘
            markup = Markup.new
            btn = ->(text : String, reason : ReportReason) {
              data = "Report:#{author_id}:#{target_user_id}:#{target_msg_id}:#{reason.value}"
              Button.new(text: text, callback_data: data)
            }

            if ReportCommander.is_file? reply_msg
              markup << [btn.call(t("report.virus_file"), Reason::VirusFile)]
              markup << [btn.call(t("report.promo_file"), Reason::PromoFile)]
            else
              markup << [btn.call(t("report.mass_ad"), Reason::MassAd)]
              markup << [btn.call(t("report.halal"), Reason::Halal)]
              markup << [btn.call(t("report.bocai"), Reason::Bocai)]
              markup << [btn.call(t("report.adname"), Reason::Adname)]
            end

            text = t "report.admin_reply", {user_id: target_user_id, voting_channel: bot.voting_channel}
            # 缓存被举报用户
            Cache.carving_report_target_msg chat_id, target_msg_id, target_user
            bot.send_message(
              msg.chat.id,
              text: text,
              reply_to_message_id: msg_id,
              reply_markup: markup
            )
          end
        if sended_msg
          # 清理完成的举报
          _del_msg_id = sended_msg.message_id
          Model::CleanMode.working chat_id, CleanDeleteTarget::Report do
            spawn bot.delete_message chat_id, _del_msg_id
            spawn bot.delete_message chat_id, msg_id
          end
        end
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

    def repeat?(chat_id, msg_id)
      if r = Model::Report.repeat?(chat_id, msg_id)
        "https://t.me/#{bot.voting_channel}/#{r.post_id}"
      end
    end
  end
end
