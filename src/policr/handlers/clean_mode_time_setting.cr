module Policr
  class CleanModeTimeSettingHandler < Handler
    alias DeleteTarget = CleanDeleteTarget

    allow_edit # 处理编辑消息

    @reply_msg_id : Int32?
    @data : {Model::CleanMode, DeleteTarget}?

    def match(msg)
      role = KVStore.enabled_trust_admin?(msg.chat.id) ? :admin : :creator

      all_pass? [
        (user = msg.from),
        bot.has_permission?(msg.chat.id, user.id, role),
        (reply_msg = msg.reply_to_message),
        (@reply_msg_id = reply_msg.message_id),
        (@data = Cache.clean_mode_time_msg?(msg.chat.id, @reply_msg_id)), # 回复目标为设置干净模式延迟时间？
      ]
    end

    def handle(msg)
      if (text = msg.text) && (reply_msg_id = @reply_msg_id) && (data = @data)
        chat_id = msg.chat.id

        clean_mode, delete_target = data

        clean_mode.update_column(:delay_sec, (text.to_f * 3600).to_i)
        updated_text, updated_markup = updated_preview_settings(chat_id, delete_target)
        spawn { bot.edit_message_text(
          chat_id,
          message_id: reply_msg_id,
          text: updated_text,
          reply_markup: updated_markup
        ) }

        setting_complete_with_delay_delete msg
      end
    end

    def updated_preview_settings(chat_id, delete_target)
      midcall CleanModeCallback do
        {_callback.create_time_setting_text(chat_id, delete_target),
         _callback.create_time_setting_markup(chat_id, delete_target)}
      end || {nil, nil}
    end
  end
end
