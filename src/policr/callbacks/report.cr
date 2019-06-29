module Policr
  class ReportCallback < Callback
    alias Reason = ReportReason
    alias Status = ReportStatus
    alias UserRole = ReportUserRole

    def initialize(bot)
      super(bot, "Report")
    end

    def handle(query, msg, data)
      chat_id = msg.chat.id
      from_user_id = query.from.id

      author_id, target_user_id, target_msg_id, reason_value = data
      author_id = author_id.to_i
      target_user_id = target_user_id.to_i
      target_msg_id = target_msg_id.to_i
      reason_value = reason_value.to_i

      unless from_user_id == author_id.to_i
        bot.answer_callback_query(query.id, text: t("unrelated_warning"), show_alert: true)
        return
      end

      # 转发举报消息
      begin
        snapshot_message = bot.forward_message(
          chat_id: "@#{bot.snapshot_channel}",
          from_chat_id: chat_id,
          message_id: target_msg_id
        )
      rescue e : TelegramBot::APIException
        bot.answer_callback_query(query.id, text: "举报发起失败，这可能是因为你举报了不支持的消息类型。如果您认为这是一个功能故障，请进入交流群反馈。")
        return
      end

      # 如果举报人具备权限，删除消息并封禁用户。并获得举报人角色
      role =
        if bot.is_admin?(chat_id, from_user_id)
          if bot.has_permission?(chat_id, from_user_id, :creator, dirty: false)
            UserRole::Creator
          elsif DB.trust_admin?(msg.chat.id) # 受信管理员
            UserRole::TrustedAdmin
          else
            UserRole::Admin
          end
        else
          UserRole::Member
        end
      unless role == UserRole::Member # 具备权限
        spawn bot.delete_message(chat_id, target_msg_id)
        spawn bot.kick_chat_member(chat_id, target_user_id)
      end

      # 生成举报并入库
      if snapshot_message
        r = Model::Report.create(
          {
            author_id: from_user_id.to_i64,
            post_id:   snapshot_message.message_id,
            target_id: target_user_id.to_i64,
            reason:    reason_value,
            status:    Status::Begin.value,
            role:      role.value,
            from_chat: chat_id.to_i64,
          }
        )
      end
      # 生成投票
      if r
        text = "举报发起人：[#{r.author_id}](tg://user?id=#{r.author_id})\n举报人身份：#{make_role(r.role)}\n举报目标快照：[#{r.post_id}](https://t.me/#{bot.snapshot_channel}/#{r.post_id})\n被执行用户：[#{r.target_id}](tg://user?id=#{r.target_id})\n举报原因：#{make_reason(r.reason)}\n当前状态：#{make_status(r.status)}"

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
        voting_msg = bot.send_message(
          chat_id: "@#{bot.voting_channel}",
          text: text,
          disable_web_page_preview: true,
          parse_mode: "markdown",
          reply_markup: markup
        )
      end

      # 响应举报生成结果
      if voting_msg
        text = "举报已经生成（[在这里](https://t.me/#{bot.voting_channel}/#{voting_msg.message_id})），具有投票权的用户会对举报内容进行表决。注意了，[您](tg://user?id=#{from_user_id})作为投票发起人即便有公投权也不能进行投票。另外举报受理成功也会在本群通知。"
        bot.edit_message_text(
          chat_id: chat_id,
          message_id: msg.message_id,
          text: text,
          disable_web_page_preview: true,
          parse_mode: "markdown"
        )
      end
    end

    def make_role(role_value)
      case UserRole.new(role_value)
      when UserRole::Unknown
        "未知"
      when UserRole::Creator
        "群主"
      when UserRole::TrustedAdmin
        "受信管理员"
      when UserRole::Admin
        "管理员"
      when UserRole::Member
        "群成员"
      end
    end

    def make_reason(reason_value)
      case Reason.new(reason_value)
      when Reason::Unknown
        "未记录"
      when Reason::Spam
        "恶意散播广告"
      when Reason::Halal
        "未识别的清真"
      end
    end

    def make_status(status_value)
      case Status.new(status_value)
      when Status::Unknown
        "不明"
      when Status::Begin
        "表决中"
      when Status::Reject
        "不受理"
      when Status::Accept
        "被处理"
      when Status::Unban
        "通过申诉"
      end
    end
  end
end
