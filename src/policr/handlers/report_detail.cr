module Policr
  class ReportDetailHandler < Handler
    @target_user : TelegramBot::User?

    def match(msg)
      all_pass? [
        (reply_msg = msg.reply_to_message),
        (reply_msg_id = reply_msg.message_id),
        (@target_user = Cache.report_detail_msg?(msg.chat.id, reply_msg_id)), # 回复目标为举报详情？
      ]
    end

    def handle(msg)
      if (target_user = @target_user) && (from_user = msg.from) && (detail = msg.text)
        target_user_id = target_user.id.to_i64
        # 入库举报
        begin
          data =
            {
              author_id:          from_user.id.to_i64,
              post_id:            0, # 临时 post id，举报消息发布以后更新
              target_snapshot_id: 0, # 其它原因的举报没有快照消息
              target_user_id:     target_user_id,
              target_msg_id:      0, # 其它原因的举报没有目标消息
              reason:             ReportReason::Other.value,
              status:             ReportStatus::Begin.value,
              role:               0, # 其它原因的举报没有发起人身份
              from_chat_id:       msg.chat.id.to_i64,
              detail:             detail,
            }
          r = Model::Report.create!(data)
        rescue e : Exception
          bot.log "Save reporting data failed: #{e.message}"
          return
        end
        # 生成投票
        if r
          midcall ReportCallback do
            text = callback.make_text(
              r.author_id, r.role, r.target_snapshot_id,
              target_user_id, r.reason, r.status, detail
            )
            report_id = r.id
            markup = Markup.new
            make_btn = ->(text : String, voting_type : String) {
              Button.new(text: text, callback_data: "Voting:#{report_id}:#{voting_type}")
            }
            markup << [
              make_btn.call("👍", "agree"),
              make_btn.call("🙏", "abstention"),
              make_btn.call("👎", "oppose"),
            ]

            voting_msg =
              begin
                bot.send_message "@#{bot.voting_channel}", text, reply_markup: markup
              rescue e : TelegramBot::APIException
                # 回滚已入库的举报
                Model::Report.delete(r.id)
                _, reason = bot.parse_error(e)
                bot.reply msg, "举报发起失败，#{reason}"
              end
            if voting_msg
              r.update_column(:post_id, voting_msg.message_id)
            end
          end
        end
        bot.reply msg, "举报完成。"
      end
    end
  end
end
