module Policr
  handler PrivateForward do
    match do
      all_pass? [
        from_private_chat?(msg),
        msg.forward_from,
      ]
    end

    handle do
      make_btn = ->(action : String) {
        Button.new(text: t("private_forward.#{action}"), callback_data: "PrivateForward:#{action}")
      }

      markup = Markup.new

      markup << [make_btn.call "report"]
      markup << [make_btn.call "view_userinfo"]
      bot.send_message(
        msg.chat.id,
        text: t("private_forward.desc"),
        reply_to_message_id: msg.message_id,
        reply_markup: markup
      )
    end
  end
end
