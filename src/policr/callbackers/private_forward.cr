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

        async_response

        bot.edit_message_text(
          chat_id,
          message_id: message_id,
          text: text,
          reply_markup: markup
        )
      when "view_userinfo"
        if (from_user = query.from) && (reply_msg = msg.reply_to_message) && (target_user = reply_msg.forward_from)
          fu = FromUser.new(target_user)
          fullname = fu.fullname
          userid = fu.user_id
          reported_times = Model::Report.times_by_target_user userid
          valid_reported_total = Model::Report.valid_reported_total userid
          appeal_times = Model::Appeal.valid_times userid
          report_times = Model::Report.times_by_author userid
          text = t "private_forward.userinfo", {
            fullname:             fullname,
            userid:               userid,
            reported_times:       reported_times,
            valid_reported_total: valid_reported_total,
            appeal_times:         appeal_times,
            report_times:         report_times,
          }

          async_response

          bot.edit_message_text(
            chat_id,
            message_id: message_id,
            text: text
          )
        end
      else
        invalid_keyboard
      end
    end

    macro put_item_list(list)
      {% for reason in list %}
        markup << [make_btn.call(t("report.{{reason.id}}"), ReportReason::{{reason.camelcase.id}})]
      {% end %}
    end
  end
end
