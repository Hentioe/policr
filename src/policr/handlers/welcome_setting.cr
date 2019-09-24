module Policr
  handler WelcomeSetting do
    alias Welcome = Model::Welcome

    allow_edit # 处理编辑消息

    target :fields

    match do
      target :group do
        all_pass? [
          (@reply_msg_id = _reply_msg_id),
          Cache.welcome_setting_msg?(msg.chat.id, @reply_msg_id), # 回复目标为设置欢迎消息指令？
          (user = msg.from),
          has_permission?(_group_id, user.id),
        ]
      end
    end

    handle do
      retrieve [(text = msg.text)] do
        chat_id = msg.chat.id
        begin
          WelcomeContentParser.parse! text
          Welcome.set_content!(_group_id, text)

          updated_text, updated_markup = updated_settings_preview(_group_id, _group_name)
          spawn { bot.edit_message_text(
            chat_id,
            message_id: _reply_msg_id,
            text: updated_text,
            reply_markup: updated_markup
          ) }

          setting_complete_with_delay_delete msg
        rescue e : Exception
          bot.send_message chat_id, e.to_s
        end
      end
    end

    def updated_settings_preview(group_id, group_name)
      midcall WelcomeCommander do
        {
          _commander.create_text(group_id, group_name),
          _commander.create_markup(group_id),
        }
      end || {nil, nil}
    end
  end
end
