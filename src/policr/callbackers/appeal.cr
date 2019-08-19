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
            reason:     ReportCallbacker.make_reason(r.reason),
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
      when "not_agree"
        report_id = data[1].to_i
        if report = Model::Report.find(report_id)
          appeals = report.add_appeals({:author_id => chat_id.to_i32, :done => false})
          if appeals && appeals.size > 0
            text = t("appeal.contact_me", {appeal_id: appeals[0].id})
            bot.edit_message_text(chat_id, message_id: msg_id, text: text)
          else
            bot.edit_message_text(
              chat_id,
              message_id: msg_id,
              text: t("appeal.retry")
            )
          end
        else
          bot.answer_callback_query(query.id, text: t("appeal.report.not_exists"), show_alert: true)
        end
      when "agree" # 我认同
        report_id = data[1].to_i
        if report = Model::Report.find(report_id)
          unless report.status == ReportStatus::Accept.value
            bot.answer_callback_query(query.id, text: t("appeal.report.not_valid"), show_alert: true)
            return
          end
          spawn bot.answer_callback_query(query.id)
          spawn bot.edit_message_text(chat_id, message_id: msg_id, text: t("appeal.verification.waiting"))
          # 生成验证问题
          verification = ImageVerification.new chat_id: chat_id
          question = verification.make
          title = t("appeal.verification.title", {hint: question.title})
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
          bot.answer_callback_query(query.id, text: t("appeal.report.not_exists"), show_alert: true)
        end
      when "verification"
        report_id = data[1].to_i
        chooese = data[2]

        if (reply_msg = msg.reply_to_message) && (report = Model::Report.find(report_id))
          flow_msg_id = reply_msg.message_id

          unless report.status == ReportStatus::Accept.value
            bot.answer_callback_query(query.id, text: t("appeal.not_valid"), show_alert: true)
            return
          end

          spawn bot.delete_message chat_id, msg_id
          if Model::TrueIndex.contains?(chat_id, msg_id, chooese)
            content = AppealCallbacker.make_text ReportReason.new(report.reason)
            text = t("appeal.need_reply", {content: content})
            bot.edit_message_text(
              chat_id,
              message_id: flow_msg_id,
              text: text
            )
            # 生成申诉
            appeals = report.add_appeals({:author_id => chat_id.to_i32, :done => false})
            if appeals && appeals.size > 0
              # 标记申诉流程消息
              Cache.carving_appeal_flow_msg chat_id, flow_msg_id, appeals[0]
            else
              bot.edit_message_text(
                chat_id,
                message_id: flow_msg_id,
                text: t("appeal.retry")
              )
            end
          else # 验证失败
            bot.edit_message_text(
              chat_id,
              message_id: flow_msg_id,
              text: t("appeal.verification.failure")
            )
          end
        else
          bot.answer_callback_query(query.id, text: t("appeal.not_found"), show_alert: true)
        end
      else # 失效键盘
        bot.answer_callback_query(query.id, text: t("invalid_callback"), show_alert: true)
      end
    end

    def self.make_behavior(reason)
      case reason
      when ReportReason::Unknown
        t "appeal.reason.unknown"
      when ReportReason::MassAd
        t "appeal.reason.mass_ad"
      when ReportReason::Halal
        t "appeal.reason.halal"
      when ReportReason::Other
        t "appeal.reason.other"
      when ReportReason::Hateful
        t "appeal.reason.hateful"
      when ReportReason::Adname
        t "appeal.reason.adname"
      when ReportReason::VirusFile
        t "appeal.reason.virus_file"
      when ReportReason::PromoFile
        t "appeal.reason.promo_file"
      else
        t "appeal.reason.unknown"
      end
    end

    def self.make_text(reason)
      behavior = make_behavior(reason)
      t "appeal.reply_content", {behavior: behavior}
    end
  end
end
