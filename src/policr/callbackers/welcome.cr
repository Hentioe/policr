module Policr
  callbacker Welcome do
    alias Welcome = Model::Welcome

    def handle(query, msg, data)
      target_group do
        name = data[0]

        case name
        when "link_preview"
          is_enabled = Welcome.link_preview_enabled? _group_id
          is_enabled ? Welcome.disable_link_preview(_group_id) : Welcome.enable_link_preview!(_group_id)

          async_response

          updated_text, updated_markup = updated_settings_preview _group_id, _group_name

          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: updated_text,
            reply_markup: updated_markup
          )
        when "enable"
          unless Welcome.find_by_chat_id(_group_id)
            bot.answer_callback_query(query.id, text: t("welcome.missing_content"), show_alert: true)
            return
          end
          selected = Welcome.enabled?(_group_id)
          selected ? Welcome.disable(_group_id) : Welcome.enable!(_group_id)

          async_response

          updated_text, updated_markup = updated_settings_preview _group_id, _group_name

          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: updated_text,
            reply_markup: updated_markup
          )
        when "sticker_mode"
          is_enabled = Welcome.sticker_mode_enabled? _group_id
          begin
            is_enabled ? Welcome.disable_sticker_mode(_group_id) : Welcome.enable_sticker_mode!(_group_id)

            async_response

            updated_text, updated_markup = updated_settings_preview _group_id, _group_name

            bot.edit_message_text(
              _chat_id,
              message_id: msg.message_id,
              text: updated_text,
              reply_markup: updated_markup
            )
          rescue e : Exception
            case e.message
            when "Uncreated content"
              bot.answer_callback_query(query.id, t "welcome.missing_content")
            when "Missing sticker_file_id"
              bot.answer_callback_query(query.id, t "welcome.missing_sticker")
            else
              bot.answer_callback_query(query.id, e.to_s)
            end
          end
        else # 失效键盘
          invalid_keyboard
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
