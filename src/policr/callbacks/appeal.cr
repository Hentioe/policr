module Policr
  callbacker Appeal do
    DATE_FORMAT = "%Y-%m-%d %H:%M"

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
            begin_date: begin_date.to_s(DATE_FORMAT),
            end_date:   end_date.to_s(DATE_FORMAT),
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
      when "agree" # 我认同
        report_id = data[1].to_i
        if report = Model::Report.find(report_id)
          unless report.status == ReportStatus::Accept.value
            bot.answer_callback_query(query.id, text: t("这条举报（暂时）没有生效。"), show_alert: true)
            return
          end
          spawn bot.answer_callback_query(query.id)
          spawn bot.edit_message_text(chat_id, message_id: msg_id, text: "等待验证……")
          # 生成验证问题
          verification = ImageVerification.new chat_id: chat_id
          question = verification.make
          title = "请确认「#{question.title}」完成验证以继续申诉流程。"
          answers = question.answers

          btn = ->(text : String, chooese_id : Int32) {
            Button.new(text: text, callback_data: "Appeal:verification:#{report_id}:#{chooese_id}")
          }
          markup = Markup.new
          i = 0
          answer_list = answers.map do |answer_line|
            tmp_ans = answer_line.map do |answer|
              i += 1
              btn.call(answer, i)
            end
            tmp_ans = tmp_ans.shuffle if question.is_discord
            tmp_ans
          end
          answer_list = answer_list.shuffle if question.is_discord # 乱序答案列表
          answer_list.each { |ans_btns| markup << ans_btns }
          # 发送验证消息
          if (image = question.file_path) && (sended_msg = bot.send_photo(
               chat_id,
               File.new(image),
               caption: title,
               reply_to_message_id: msg_id,
               reply_markup: markup,
               parse_mode: "markdown"
             ))
            verification.storage(sended_msg.message_id)
          end
        else
          bot.answer_callback_query(query.id, text: t("这条举报已经不存在。"), show_alert: true)
        end
      when "verification"
        report_id = data[1].to_i
        chooese = data[2]

        if (reply_msg = msg.reply_to_message) && (report = Model::Report.find(report_id))
          unless report.status == ReportStatus::Accept.value
            bot.answer_callback_query(query.id, text: t("这条举报（暂时）没有生效。"), show_alert: true)
            return
          end

          spawn bot.delete_message chat_id, msg_id
          if Model::TrueIndex.contains?(chat_id, msg_id, chooese)
            make_behavior = ->(reason : ReportReason) {
              case reason
              when ReportReason::Unknown
                "产生大家不赞同的行为"
              when ReportReason::MassAd
                "散播广告"
              when ReportReason::Halal
                "发表清真消息"
              when ReportReason::Other
                "产生大家不赞同的行为"
              when ReportReason::Hateful
                "发表充满仇恨或恐怖主义内容"
              when ReportReason::Adname
                "使用广告昵称"
              when ReportReason::VirusFile
                "传播病毒或恶意程序"
              when ReportReason::PromoFile
                "传播推广或恶意文件"
              else
                "产生大家不赞同的行为"
              end
            }
            behavior = make_behavior.call(ReportReason.new(report.reason))
            text = "验证成功，请继续。回复「我不再继续#{behavior}，我遵守大家共同制定的规定，我不会找举报人的麻烦」至本消息即可解除黑名单 (ゝ∀･)b\n\n请尽快回复，本消息不保证时效性。"
            bot.edit_message_text(
              chat_id,
              message_id: reply_msg.message_id,
              text: text
            )
          else # 验证失败
            bot.edit_message_text(
              chat_id,
              message_id: reply_msg.message_id,
              text: "您没能验证成功，申诉失败。"
            )
          end
        else
          bot.answer_callback_query(query.id, text: "没有获取到流程消息或没有找到该条举报～", show_alert: true)
        end
      else # 失效键盘
        bot.answer_callback_query(query.id, text: t("invalid_callback"), show_alert: true)
      end
    end
  end
end
