module Policr
  MIN_TORTURE_SEC = 30

  handler TortureTimeSetting do
    allow_edit # 处理编辑消息
    target :fields

    match do
      target :group do
        all_pass? [
          (@reply_msg_id = _reply_msg_id),
          Cache.torture_time_msg?(msg.chat.id, @reply_msg_id), # 回复验证时间？
          msg.text,
          (user = msg.from),
          has_permission?(_group_id, user.id),
        ]
      end
    end

    handle do
      retrieve [(text = msg.text)] do
        sec = text.to_i

        if sec > 0 && sec < MIN_TORTURE_SEC # 时间不合法
          bot.reply msg, t("torture.time_too_short", {min_sec: MIN_TORTURE_SEC})
        else
          chat_id = msg.chat.id

          Model::VerificationMode.set_torture_sec! _group_id, sec

          updated_text, updated_markup = updated_preview_settings(_group_id, _group_name)
          spawn { bot.edit_message_text(
            chat_id,
            message_id: _reply_msg_id,
            text: updated_text,
            reply_markup: updated_markup
          ) }

          setting_complete_with_delay_delete msg
        end
      end
    end

    def updated_preview_settings(group_id, group_name)
      midcall TortureTimeCommander do
        {
          _commander.create_text(group_id, group_name),
          _commander.create_markup(group_id),
        }
      end || {nil, nil}
    end
  end
end
