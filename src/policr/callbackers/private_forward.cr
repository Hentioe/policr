module Policr
  callbacker PrivateForward do
    def handle(query, msg, data)
      chat_id = msg.chat.id
      from_user_id = query.from.id
      chooese = data[0]

      message_id = msg.message_id

      case chooese
      when "report"
        if (from_user = query.from) && (reply_msg = msg.reply_to_message) && (target_user = reply_msg.forward_from)
          error_msg = midcall ReportCommander do
            author_id = from_user.id
            target_user_id = target_user.id
            _commander.check_legality(author_id, target_user_id)
          end

          if error_msg # 如果举报不合法响应错误
            bot.answer_callback_query(query.id, text: error_msg, show_alert: true)
            return
          end

          is_file = ReportCommander.is_file? reply_msg
        end
        markup = Markup.new
        make_btn = ->(text : String, reason : ReportReason) {
          Button.new(text: text, callback_data: "PrivateForwardReport:#{reason.value}")
        }

        unless is_file
          put_item_list ["mass_ad", "halal", "bocai", "adname", "other"]
        else
          put_item_list ["virus_file", "promo_file", "other"]
        end

        text = t "private_forward.report_reason_chooese"
        bot.edit_message_text(
          chat_id,
          message_id: message_id,
          text: text,
          reply_markup: markup
        )
      end
    end

    macro put_item_list(list)
      {% for reason in list %}
        markup << [make_btn.call(t("report.{{reason.id}}"), ReportReason::{{reason.camelcase.id}})]
      {% end %}
    end
  end
end
