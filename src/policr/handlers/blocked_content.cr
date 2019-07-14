module Policr
  class BlockedContentHandler < Handler
    @reply_msg_id : Int32?

    def match(msg)
      role = KVStore.trust_admin?(msg.chat.id) ? :admin : :creator

      all_pass? [
        (user = msg.from),
        (reply_msg = msg.reply_to_message),
        (@reply_msg_id = reply_msg.message_id),
        Cache.blocked_content_msg?(msg.chat.id, @reply_msg_id), # 回复目标为设置来源指令？
        bot.has_permission?(msg.chat.id, user.id, role),
      ]
    end

    def handle(msg)
      if (text = msg.text) && (reply_msg_id = @reply_msg_id)
        chat_id = msg.chat.id

        Model::BlockContent.update_expression(chat_id, text)

        update_text, update_markup = update_preview_settings(chat_id)
        spawn {
          bot.edit_message_text(
            chat_id, message_id: reply_msg_id, text: update_text,
            reply_markup: update_markup, parse_mode: "markdown"
          )
        }

        setting_complete_with_delay_delete msg
      end
    end

    def update_preview_settings(chat_id)
      midcall StrictModeCallback do
        {_callback.create_content_blocked_text(chat_id),
         _callback.create_content_blocked_markup(chat_id)}
      end || {nil, nil}
    end
  end
end
