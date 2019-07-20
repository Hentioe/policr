module Policr
  MIN_TORTURE_SEC = 30

  class TortureTimeSettingHandler < Handler
    allow_edit # 处理编辑消息
    target :fields

    def match(msg)
      target :group do
        role = KVStore.enabled_trust_admin?(_group_id) ? :admin : :creator

        all_pass? [
          msg.text,
          (user = msg.from),
          bot.has_permission?(_group_id, user.id, role),
          (@reply_msg_id = _reply_msg_id),
          Cache.torture_time_msg?(msg.chat.id, @reply_msg_id), # 回复验证时间？
        ]
      end
    end

    def handle(msg)
      if (group_id = @group_id) && (reply_msg_id = @reply_msg_id)
        sec =
          if text = msg.text
            text.to_i
          else
            DEFAULT_TORTURE_SEC
          end
        if sec > 0 && sec < MIN_TORTURE_SEC # 时间不合法
          bot.reply msg, t("torture.time_too_short", {min_sec: MIN_TORTURE_SEC})
        else
          chat_id = msg.chat.id

          KVStore.set_torture_sec(group_id, sec)

          updated_text, updated_markup = updated_preview_settings(group_id)
          spawn { bot.edit_message_text(
            chat_id,
            message_id: reply_msg_id,
            text: updated_text,
            reply_markup: updated_markup
          ) }

          setting_complete_with_delay_delete msg
        end
      end
    end

    def updated_preview_settings(group_id)
      midcall TortureTimeCommander do
        {_commander.text(group_id), _commander.create_markup}
      end || {nil, nil}
    end
  end
end
