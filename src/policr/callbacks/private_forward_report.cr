module Policr
  class PrivateForwardReportCallback < Callback
    def initialize(bot)
      super(bot, "PrivateForwardReport")
    end

    def handle(query, msg, data)
      chat_id = msg.chat.id
      chooese = data[0]

      reason_value = chooese.to_i
      msg_id = msg.message_id

      case ReportReason.new(reason_value)
      when ReportReason::Spam, ReportReason::Halal
        midcall ReportCallback do
          if (reply_msg = msg.reply_to_message) && (target_user = reply_msg.forward_from) && (from_user = query.from)
            target_msg_id = reply_msg.message_id
            target_user_id = target_user.id.to_i64
            from_user_id = from_user.id.to_i64

            _callback.make_report chat_id, msg_id, target_msg_id, target_user_id, from_user_id, reason_value, query: query
          end
        end
      when ReportReason::Other
        text = t "private_forward_report.other"
        if (reply_msg = msg.reply_to_message) && (target_user = reply_msg.forward_from)
          Cache.carving_report_detail_msg chat_id, msg_id, target_user
        end
        bot.edit_message_text chat_id, message_id: msg_id, text: text
      end
    end
  end
end
