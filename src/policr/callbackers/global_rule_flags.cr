module Policr
  callbacker GlobalRuleFlags do
    alias GlobalRuleFlag = Model::GlobalRuleFlag

    def handle(query, msg, data)
      target_group do
        chat_id = msg.chat.id
        msg_id = msg.message_id

        action = data[0]

        case action
        when "action_hint"
          bot.answer_callback_query(query.id, text: "通过下列单选按钮设置动作～")
        when "subscribe"
          selected = GlobalRuleFlag.enabled? _group_id
          selected ? GlobalRuleFlag.disable(_group_id) : GlobalRuleFlag.enable!(_group_id)

          updated_text, updated_markup = update_preview_settings _group_id, _group_name

          async_response

          bot.edit_message_text(
            chat_id,
            message_id: msg_id,
            text: updated_text,
            reply_markup: updated_markup
          )
        when "report"
          selected = GlobalRuleFlag.reported? _group_id
          if !selected &&
             GlobalRuleFlag.action_is?(_group_id, HitAction::Delete) # 如果启用上报且处于删除动作
            bot.answer_callback_query(query.id, text: "删除动作下无法启用上报，这是为了避免频繁的重复上报。建议切换到「禁言」动作。", show_alert: true)
            return
          end
          begin
            selected ? GlobalRuleFlag.disable_report(_group_id) : GlobalRuleFlag.enable_report!(_group_id)
            updated_text, updated_markup = update_preview_settings _group_id, _group_name

            async_response

            bot.edit_message_text(
              chat_id,
              message_id: msg_id,
              text: updated_text,
              reply_markup: updated_markup
            )
          rescue e : Exception
            bot.answer_callback_query(query.id, text: e.to_s, show_alert: true)
          end
        when "delete"
          def_switch "delete"
        when "restrict"
          def_switch "restrict"
        when "ban"
          def_switch "ban"
        else # 失效键盘
          invalid_keyboard
        end
      end
    end

    macro def_switch(action_s)
      begin
        {% if action_s == "delete" %}
          if GlobalRuleFlag.reported?(_group_id)
            bot.answer_callback_query(query.id, text: "启用上报的情况下无法切换到删除动作，这是为了避免频繁的重复上报。", show_alert: true)
            return
          end
        {% end %}
        GlobalRuleFlag.switch_action! _group_id, HitAction::{{action_s.id.camelcase}}
        updated_text, updated_markup = update_preview_settings _group_id, _group_name

        async_response

        bot.edit_message_text(
          chat_id,
          message_id: msg_id,
          text: updated_text,
          reply_markup: updated_markup
        )
      rescue e : Exception
        bot.answer_callback_query(query.id, text: e.to_s, show_alert: true)
      end
    end

    def update_preview_settings(group_id, group_name)
      midcall GlobalRuleFlagsCommander do
        {
          _commander.create_text(group_id, group_name),
          _commander.create_markup(group_id),
        }
      end || {nil, nil}
    end
  end
end
