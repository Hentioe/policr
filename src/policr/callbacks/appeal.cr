module Policr
  callbacker Appeal do
    def handle(query, msg, data)
      chat_id = msg.chat.id
      msg_id = msg.message_id
      user_id =
        if user = query.from
          user.id
        else
          0
        end
      action = data[0]

      case action
      when "start" # 开始申诉
        if (report = Model::Report.first_valid(user_id)) && (r = report)
          begin_date = r.created_at || Time.new(0, 0, 0)
          end_date = r.updated_at || Time.new(0, 0, 0)

          text = t("appeal.report.detail", {
            begin_date: begin_date.to_s("%Y-%m-%d %H:%M"),
            end_date:   end_date.to_s("%Y-%m-%d %H:%M"),
            reason:     ReportCallback.make_reason(r.reason),
            link:       "t.me/#{bot.voting_channel}/#{report.post_id}",
          })
          make_btn = ->(action : String) {
            Button.new(text: t("appeal.#{action}"), callback_data: "Appeal:#{action}:#{r.id}")
          }
          markup = Markup.new
          markup << [make_btn.call "agree"]
          markup << [make_btn.call "not_agree"]
          bot.edit_message_text(chat_id, message_id: msg_id, text: text, reply_markup: markup)
        else
          bot.edit_message_text chat_id, message_id: msg_id, text: t("appeal.non_blacklist")
        end
      else # 失效键盘
        bot.answer_callback_query(query.id, text: t("invalid_callback"), show_alert: true)
      end
    end
  end
end
