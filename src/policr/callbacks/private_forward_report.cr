module Policr
  class PrivateForwardReportCallback < Callback
    def initialize(bot)
      super(bot, "PrivateForwardReport")
    end

    def handle(query, msg, data)
      chat_id = msg.chat.id
      chooese = data[0]

      message_id = msg.message_id

      case chooese
      when "other"
        text = t "private_forward_report.other"
        if (reply_msg = msg.reply_to_message) && (target_user = reply_msg.forward_from)
          Cache.carving_torture_report_detail_msg chat_id, msg.message_id, target_user
        end
        bot.edit_message_text(chat_id: chat_id, message_id: message_id,
          text: text, disable_web_page_preview: true, parse_mode: "markdown")
      end
    end
  end
end
