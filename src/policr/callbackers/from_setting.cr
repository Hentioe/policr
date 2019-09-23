module Policr
  callbacker FromSetting do
    alias From = Model::From

    def handle(query, msg, data)
      target_group do
        name, toggle = data

        unless toggle == "toggle"
          bot.answer_callback_query(query.id, text: t("invalid_callback"), show_alert: true)
        end

        case name
        when "enable"
          unless From.find_by_chat_id(_group_id)
            bot.answer_callback_query(query.id, text: t("from.not_set"), show_alert: true)
            return
          end
          selected = From.enabled?(_group_id)
          selected ? From.disable(_group_id) : From.enable!(_group_id)
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
      midcall FromCommander do
        {_commander.create_text(group_id, group_name), _commander.create_markup(group_id)}
      end || {nil, nil}
    end
  end
end
