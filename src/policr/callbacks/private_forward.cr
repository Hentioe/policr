module Policr
  class PrivateForwardCallback < Callback
    def initialize(bot)
      super(bot, "PrivateForward")
    end

    def handle(query, msg, data)
      chat_id = msg.chat.id
      from_user_id = query.from.id
      chooese = data[0]

      message_id = msg.message_id

      case chooese
      when "report"
        markup = Markup.new
        markup << [Button.new(text: t("private_forward.other"), callback_data: "PrivateForwardReport:other")]

        text = t "private_forward.report_reason_chooese"
        bot.edit_message_text(chat_id: chat_id, message_id: message_id,
          text: text, disable_web_page_preview: true, reply_markup: markup, parse_mode: "markdown")
      end
    end
  end
end
