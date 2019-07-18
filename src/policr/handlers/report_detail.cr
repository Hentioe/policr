module Policr
  class ReportDetailHandler < Handler
    @target_user : TelegramBot::User?
    @reply_msg_id : Int32?

    allow_edit

    match do
      all_pass? [
        (reply_msg = msg.reply_to_message),
        (@reply_msg_id = reply_msg.message_id),
        (@target_user = Cache.report_detail_msg?(msg.chat.id, @reply_msg_id)), # 回复目标为举报详情？
      ]
    end

    handle do
      if (target_user = @target_user) && (reply_msg_id = @reply_msg_id) && (from_user = msg.from) && (detail = msg.text)
        target_user_id = target_user.id.to_i64
        from_user_id = from_user.id.to_i64

        if exists_r = Model::Report.where {
             (_target_user_id == target_user_id) & (_author_id == from_user_id) & (_target_msg_id == reply_msg_id)
           }.first
          # 备份现在的举报详情
          detail_back = exists_r.detail
          # 更新举报详情
          exists_r.update_column(:detail, detail)
          # 编辑举报消息
          midcall ReportCallback do
            report = exists_r
            text = _callback.make_text(
              report.author_id,
              report.role,
              report.target_snapshot_id,
              report.target_user_id,
              report.reason,
              report.status,
              escape_markdown(report.detail)
            )
            begin
              bot.edit_message_text(
                "@#{bot.voting_channel}",
                message_id: exists_r.post_id,
                text: text,
                reply_markup: _callback.create_voting_markup(report.id)
              )
              bot.reply msg, t("private_forward_report.update_success_for_other")
            rescue e : TelegramBot::APIException
              _, reason = bot.parse_error(e)
              # 回滚更新
              exists_r.update_column(:detail, detail_back)
              bot.reply msg, t("private_forward_report.failure_for_other", {reason: reason})
            end
          end
        else
          # 入库举报
          begin
            data =
              {
                author_id:          from_user_id,
                post_id:            0, # 临时 post id，举报消息发布以后更新
                target_snapshot_id: 0, # 其它原因的举报没有快照消息
                target_user_id:     target_user_id,
                target_msg_id:      reply_msg_id,
                reason:             ReportReason::Other.value,
                status:             ReportStatus::Begin.value,
                role:               0, # 其它原因的举报没有发起人身份
                from_chat_id:       msg.chat.id.to_i64,
                detail:             detail,
              }
            r = Model::Report.create(data)
            # 生成投票
            if r
              midcall ReportCallback do
                if _callback.create_report_voting chat_id: msg.chat.id, report: r, reply_to_message_id: msg.message_id
                  bot.reply msg, t("private_forward_report.success_for_other")
                end
              end
            end
          rescue e : Exception
            bot.log "Save reporting data failed: #{e.message}"
            return
          end
        end
      end
    end
  end
end
