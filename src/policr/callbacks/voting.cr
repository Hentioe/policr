module Policr
  class VotingCallback < Callback
    alias Reason = ReportReason
    alias Status = ReportStatus
    alias UserRole = ReportUserRole
    alias VotingType = VoteType

    def initialize(bot)
      super(bot, "Voting")
    end

    def handle(query, msg, data)
      chat_id = msg.chat.id
      from_user_id = query.from.id

      report_id, voting_type = data
      report_id = report_id.to_i

      # 非管理员无权投票
      unless bot.is_admin?(msg.chat.id, from_user_id)
        bot.answer_callback_query(query.id, text: t("voting.no_permissions"), show_alert: true)
        return
      end

      # 查询举报对象
      report = Model::Report.find(report_id)
      unless report
        bot.answer_callback_query(query.id, text: t("voting.report_invalid"), show_alert: true)
        return
      end
      if report && report.status != Status::Begin.value # 状态可能不正确，刷新状态
        spawn bot.answer_callback_query(query.id, text: t("voting.report_ended"), show_alert: true)
        midcall ReportCallback do
          if r = report
            text = callback.make_text(r.author_id, r.role, r.post_id, bot.snapshot_channel, r.target_id, r.reason, r.status)
            bot.edit_message_text(chat_id: "@#{bot.voting_channel}", message_id: msg.message_id,
              text: text, disable_web_page_preview: true, parse_mode: "markdown")
          end
        end
        return
      end

      # 举报发起人无法投票
      # 例外：机器人作者作为发起人无视这条限制
      if report && report.author_id == from_user_id && (user = query.from) && (user.username != "Hentioe")
        bot.answer_callback_query(query.id, text: t("voting.author_cant_vote"), show_alert: true)
        return
      end

      # 如果结束，根据结果更新投票状态
      voting_action =
        case voting_type
        when "agree"
          VotingType::Agree
        when "abstention"
          VotingType::Abstention
        when "oppose"
          VotingType::Oppose
        else # 无效的投票动作将被视为弃权
          VotingType::Abstention
        end
      # 处理投票，取消投票还是添加投票
      # 简化实现，添加投票
      if report
        begin
          report.add_votes({:author_id => from_user_id.to_i64, :type => voting_action.value})
          spawn bot.answer_callback_query(query.id, text: t("voting.success"), show_alert: true)
        rescue e : Exception
          bot.answer_callback_query(query.id, text: t("voting.vote_failure", {reason: e.message}), show_alert: true)
        end
      end

      # 统计投票用户以往投票记录，计算权重
      # 此部分暂且略过

      # 判断当前总投票数据是否结束投票
      # 简化实现，直接更新状态
      status =
        case voting_action
        when VotingType::Agree
          Status::Accept
        when VotingType::Abstention
          Status::Begin
        when VotingType::Oppose
          Status::Reject
        else
          Status::Unknown
        end
      begin
        report.update_column(:status, status.value)
      rescue
        bot.answer_callback_query(query.id, text: t("voting.update_error"), show_alert: true)
        return
      end
      midcall ReportCallback do
        if r = report
          text = callback.make_text(r.author_id, r.role, r.post_id, bot.snapshot_channel, r.target_id, r.reason, status.value)
          spawn { bot.edit_message_text(
            chat_id: "@#{bot.voting_channel}",
            message_id: msg.message_id,
            text: text,
            disable_web_page_preview: true,
            parse_mode: "markdown") }
        end
      end

      # 如果受理，根据举报发起人身份决定是否进行来源封禁
      if status == Status::Accept && report && report.role == UserRole::Member.value && (chat_id = report.from_chat)
        spawn bot.kick_chat_member(chat_id, report.target_id)
      end

      # 如果受理，向来源群组通知举报被受理的消息
      if status == Status::Accept && (chat_id = report.from_chat)
        bot.send_message(
          chat_id: chat_id,
          text: t("voting.notify_msg", {voting_url: "https://t.me/#{bot.voting_channel}/#{msg.message_id}"}),
          disable_web_page_preview: true,
          parse_mode: "markdown"
        )
      end
    end
  end
end
