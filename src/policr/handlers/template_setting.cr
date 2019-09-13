module Policr
  handler TemplateSetting do
    allow_edit # 处理编辑消息

    target :fields

    match do
      target :group do
        role = KVStore.enabled_trust_admin?(_group_id) ? :admin : :creator

        all_pass? [
          (@reply_msg_id = _reply_msg_id),
          Cache.template_setting_msg?(msg.chat.id, @reply_msg_id), # 回复目标为设置提示模板指令？
          (user = msg.from),
          bot.has_permission?(_group_id, user.id, role),
        ]
      end
    end

    handle do
      retrieve [(text = msg.text)] do
        chat_id = msg.chat.id

        if err_msg = invalid?(text)
          bot.send_message chat_id, text: err_msg
        else
          Model::Template.set_content! _group_id, text.strip

          updated_text, updated_markup = updated_settings_preview(_group_id, _group_name)
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

    def updated_settings_preview(group_id, group_name)
      midcall TemplateCommander do
        {
          _commander.create_text(group_id, group_name),
          _commander.create_markup(group_id, group_name),
        }
      end || {nil, nil}
    end

    def invalid?(text)
      unless text =~ /\{\{\s*question\s*\}\}/
        t "template.missing_question"
      end
    end
  end
end
