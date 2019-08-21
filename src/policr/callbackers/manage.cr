module Policr
  callbacker Manage do
    def handle(query, msg, data)
      user_id =
        if user = query.from
          user.id
        else
          0
        end

      unless user_id == bot.owner_id.to_i
        bot.answer_callback_query(query.id, text: "您没有权限", show_alert: true)
        return
      end

      chat_id = msg.chat.id
      msg_id = msg.message_id
      action = data[0]

      case action
      when "jump"
        page_n = data[1].to_i

        midcall PrivateChatHandler do
          bot.edit_message_text(
            chat_id,
            message_id: msg_id,
            text: _handler.create_manage_text(page_n),
            reply_markup: _handler.create_manage_markup(page_n)
          )
        end
      end
    end
  end
end
