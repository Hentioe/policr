module Policr
  callbacker Template do
    alias Template = Model::Template

    def handle(query, msg, data)
      target_group do
        name = data[0]

        case name
        when "enable"
          Cache.carving_template_setting_msg _chat_id, msg.message_id

          unless Template.exists?(_group_id)
            bot.answer_callback_query(query.id, text: t("template.missing_content"), show_alert: true)
            return
          end
          selected = Template.enabled?(_group_id)
          selected ? Template.disable(_group_id) : Template.enable(_group_id)

          spawn bot.answer_callback_query(query.id)

          updated_text, updated_markup = updated_settings_preview _group_id, _group_name

          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: updated_text,
            reply_markup: updated_markup
          )
        else # 失效键盘
          bot.answer_callback_query(query.id, text: t("invalid_callback"), show_alert: true)
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
  end
end
