module Policr
  handler PrivateForward do
    def match(msg)
      all_pass? [
        !bot.from_group?(msg),
        msg.forward_from,
      ]
    end

    def handle(msg)
      markup = Markup.new
      markup << [Button.new(text: t("private_forward.report"), callback_data: "PrivateForward:report")]
      bot.send_message(
        msg.chat.id,
        text: t("private_forward.desc"),
        reply_to_message_id: msg.message_id,
        reply_markup: markup
      )
    end
  end
end
