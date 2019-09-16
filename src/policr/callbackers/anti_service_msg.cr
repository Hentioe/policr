module Policr
  callbacker AntiServiceMsg do
    def handle(query, msg, data)
      target_group do
        name = data[0]

        case name
        when "join_group"
          def_toggle "join_group", default: true
        when "leave_group"
          def_toggle "leave_group", default: true
        when "data_change"
          def_toggle "data_change", default: true
        when "pinned_message"
          def_toggle "pinned_message", default: true
        else # 失效键盘
          invalid_keyboard
        end
      end
    end

    macro def_toggle(target_s, default = false)
      spawn bot.answer_callback_query(query.id)
      {{ delete_target = target_s.camelcase }}
      delete_target = ServiceMessage::{{delete_target.id}}
      {% if default == false %}
        selected = Model::AntiMessage.enabled? _group_id, delete_target
      {% elsif default == true %}
        selected = !Model::AntiMessage.disabled? _group_id, delete_target
      {% end %}
      if selected
        Model::AntiMessage.disable! _group_id, delete_target
      else
        Model::AntiMessage.enable! _group_id, delete_target
      end
      updated_text, updated_markup = updated_preview_settings(_group_id, _group_name)

      bot.edit_message_text(
        _chat_id, 
        message_id: msg.message_id, 
        text: updated_text,
        reply_markup: updated_markup
      )
    end

    def updated_preview_settings(group_id, group_name)
      midcall AntiServiceMsgCommander do
        {
          _commander.create_text(group_id, group_name),
          _commander.create_markup(group_id),
        }
      end || {nil, nil}
    end
  end
end
