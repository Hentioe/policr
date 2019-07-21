module Policr
  class BlockedContentHandler < Handler
    allow_edit
    target :fields

    def match(msg)
      target :group do
        role = KVStore.enabled_trust_admin?(_group_id) ? :admin : :creator

        all_pass? [
          msg.text,
          (user = msg.from),
          bot.has_permission?(_group_id, user.id, role),
          (@reply_msg_id = _reply_msg_id),
          Cache.blocked_content_msg?(msg.chat.id, @reply_msg_id), # 回复目标为设置屏蔽内容？
        ]
      end
    end

    def handle(msg)
      retrieve [(text = msg.text)] do
        chat_id = msg.chat.id

        Model::BlockContent.update_expression(_group_id, text)

        update_text, update_markup = update_preview_settings(_group_id)
        spawn { bot.edit_message_text(
          chat_id,
          message_id: _reply_msg_id,
          text: update_text,
          reply_markup: update_markup
        ) }

        setting_complete_with_delay_delete msg
      end
    end

    def update_preview_settings(group_id)
      midcall StrictModeCallback do
        {_callback.create_content_blocked_text(group_id),
         _callback.create_content_blocked_markup(group_id)}
      end || {nil, nil}
    end
  end
end
