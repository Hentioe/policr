module Policr
  class FromSettingHandler < Handler
    allow_edit # 处理编辑消息

    target :fields

    def match(msg)
      target :group do
        role = KVStore.enabled_trust_admin?(_group_id) ? :admin : :creator

        puts Cache.from_setting_msg?(msg.chat.id, @reply_msg_id) # 回复目标为设置来源指令？
        all_pass? [
          (user = msg.from),
          bot.has_permission?(_group_id, user.id, role),
          (@reply_msg_id = _reply_msg_id),
          Cache.from_setting_msg?(msg.chat.id, @reply_msg_id), # 回复目标为设置来源指令？
        ]
      end
    end

    def handle(msg)
      if (group_id = @group_id) && (reply_msg_id = @reply_msg_id)
        chat_id = msg.chat.id

        KVStore.put_chat_from(group_id, msg.text)

        updated_text = updated_preview_settings(group_id)
        spawn {
          bot.edit_message_text chat_id, message_id: reply_msg_id, text: updated_text
        }

        setting_complete_with_delay_delete msg
      end
    end

    def updated_preview_settings(group_id)
      midcall FromCommander do
        _commander.text(group_id)
      end
    end
  end
end
