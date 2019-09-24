module Policr
  callbacker Welcome do
    alias Welcome = Model::Welcome

    def handle(query, msg, data)
      target_group do
        name = data[0]

        case name
        when "disable_link_preview"
          is_disable = Welcome.link_preview_disabled? _group_id
          is_disable ? Welcome.enable_link_preview!(_group_id) : Welcome.disable_link_preview(_group_id)

          spawn bot.answer_callback_query(query.id)

          updated_text, updated_markup = updated_settings_preview _group_id, _group_name

          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: updated_text,
            reply_markup: updated_markup
          )
        when "welcome"
          unless Welcome.find_by_chat_id(_group_id)
            bot.answer_callback_query(query.id, text: t("welcome.missing_content"), show_alert: true)
            return
          end
          selected = Welcome.enabled?(_group_id)
          selected ? Welcome.disable(_group_id) : Welcome.enable!(_group_id)

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
      midcall WelcomeCommander do
        {
          _commander.create_text(group_id, group_name),
          _commander.create_markup(group_id),
        }
      end || {nil, nil}
    end
  end
end
