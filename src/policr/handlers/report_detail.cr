module Policr
  class ReportDetailHandler < Handler
    def match(msg)
      all_pass? [
        (reply_msg = msg.reply_to_message),
        (reply_msg_id = reply_msg.message_id),
        Cache.report_detail_msg?(msg.chat.id, reply_msg_id), # 回复目标为举报详情？
      ]
    end

    def handle(msg)
      bot.reply msg, "Not implemented"
    end
  end
end
