module Policr
  class LanguageCallback < Callback
    alias Code = LanguageCode

    def initialize(bot)
      super(bot, "Language")
    end

    def handle(query, msg, data)
      target_group do
        msg_id = msg.message_id
        from_user_id = query.from.id
        name = data[0]

        lang = Model::Language.find_or_create(_group_id, data: {
          chat_id: _group_id.to_i64,
          code:    Code::ZhHans.value,
          auto:    EnableStatus::TurnOff.value,
        })

        case name
        when "zh_hans"
          def_switch "zh_hans"
        when "zh_hant"
          def_switch "zh_hant"
        when "english"
          def_switch "english"
        else # 失效键盘
          bot.answer_callback_query(query.id, text: t("invalid_callback"), show_alert: true)
        end
      end
    end

    macro def_switch(code_s)
      {{ code = code_s.camelcase }}

      lang.update_column(:code, Code::{{code.id}}.value)

      updated_text, updated_markup = updated_preview_settings(_group_id)

      spawn bot.answer_callback_query(query.id)
      bot.edit_message_text(
        _chat_id,
        message_id: msg_id,
        text: updated_text,
        reply_markup: updated_markup
      )
    end

    def updated_preview_settings(group_id)
      midcall LanguageCommander do
        {_commander.create_text(group_id), _commander.create_markup(group_id)}
      end || {nil, nil}
    end
  end
end
