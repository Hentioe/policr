module Policr
  handler AppealReply do
    @appeal : Model::Appeal?
    @flow_msg_id : Int32?

    match do
      self_left = read_state :self_left { false }

      all_pass? [
        !self_left,
        from_private_chat?(msg),
        (reply_msg = msg.reply_to_message),
        (@flow_msg_id = reply_msg.message_id),
        (@appeal = Cache.appeal_flow_msg?(msg.chat.id, reply_msg.message_id)), # 回复申诉内容？
        msg.text,
      ]
    end

    TWO_DAY_SECONDS = 60 * 60 * 24 * 2

    handle do
      if (text = msg.text) &&
         (flow_msg_id = @flow_msg_id) &&
         (appeal = @appeal) &&
         !appeal.done &&                    # 此申诉未经使用
         appeal.author_id == msg.chat.id && # 来自同一个人
         (report = appeal.report)
        chat_id = msg.chat.id
        msg_id = msg.message_id

        if report.status == ReportStatus::Accept.value
          appeal.update_column(:done, true)

          content = AppealCallbacker.make_text ReportReason.new(report.reason)
          if text.strip == content
            # 转发申诉消息到快照频道
            appeal_post_id =
              if forwarded_msg = bot.forward_message(
                   chat_id: "@#{bot.snapshot_channel}",
                   from_chat_id: chat_id,
                   message_id: msg_id
                 )
                spawn bot.delete_message chat_id, msg_id
                forwarded_msg.message_id
              end
            if appeal_post_id
              # 更新入库举报状态
              report.update_column :status, ReportStatus::Unban.value
              report.update_column :appeal_post_id, appeal_post_id
              # 更新举报消息
              if create_time = report.created_at
                create_unix = create_time.to_unix
                now_unix = Time.utc.to_unix
                # 如果大于两天则发送新举报消息，否则编辑旧举报消息
                if (now_unix - create_unix) > TWO_DAY_SECONDS
                  if sended_msg = bot.send_message(
                       "@#{bot.voting_channel}",
                       text: restore_report_text(report)
                     )
                    old_post_id = report.post_id
                    report.update_column :post_id, sended_msg.message_id
                    bot.delete_message "@#{bot.voting_channel}", old_post_id
                  end
                else
                  bot.edit_message_text(
                    "@#{bot.voting_channel}",
                    message_id: report.post_id,
                    text: restore_report_text(report)
                  )
                end
              end
              bot.edit_message_text(
                chat_id,
                message_id: flow_msg_id,
                text: t("appeal.success"),
              )
            end
          end
        else
          bot.reply msg, t("appeal.expired")
        end
      end
    end

    def restore_report_text(report)
      midcall ReportCallbacker do
        _callbacker.make_text_from_report report
      end || t("none")
    end
  end
end
