module Policr
  handler CleanModeTimeSetting do
    alias DeleteTarget = CleanDeleteTarget

    allow_edit # 处理编辑消息
    target :fields

    @data : {Model::CleanMode, DeleteTarget}?

    match do
      target :group do
        all_pass? [
          (@reply_msg_id = _reply_msg_id),
          (@data = Cache.clean_mode_time_msg?(msg.chat.id, @reply_msg_id)), # 回复目标为设置干净模式延迟时间？
          (user = msg.from),
          has_permission?(_group_id, user.id),
        ]
      end
    end

    handle do
      retrieve [(text = msg.text), (data = @data)] do
        chat_id = msg.chat.id

        clean_mode, delete_target = data

        clean_mode.update_column(:delay_sec, (text.to_f * 3600).to_i)
        updated_text, updated_markup = updated_preview_settings(_group_id, delete_target, _group_name)
        spawn { bot.edit_message_text(
          chat_id,
          message_id: _reply_msg_id,
          text: updated_text,
          reply_markup: updated_markup
        ) }

        setting_complete_with_delay_delete msg
      end
    end

    def updated_preview_settings(group_id, delete_target, group_name)
      midcall CleanModeCallbacker do
        {_callbacker.create_time_setting_text(group_id, delete_target, group_name: group_name),
         _callbacker.create_time_setting_markup(group_id, delete_target)}
      end || {nil, nil}
    end
  end
end
