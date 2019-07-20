module Policr
  class SubfunctionsCallback < Callback
    alias FunctionType = SubfunctionType

    def initialize(bot)
      super(bot, "Subfunctions")
    end

    def handle(query, msg, data)
      target_group do
        type_value, _ = data

        get_sf = ->(func_type : FunctionType) {
          Model::Subfunction.find_or_create!(_group_id, func_type, {
            chat_id: _group_id.to_i64,
            type:    func_type.value,
            status:  EnableStatus::TurnOn.value,
          })
        }

        case type_value.to_i
        when FunctionType::UserJoin.value
          def_toggle "user_join"
        when FunctionType::BotJoin.value
          def_toggle "bot_join"
        when FunctionType::BanHalal.value
          def_toggle "ban_halal"
        when FunctionType::Blacklist.value
          def_toggle "blacklist"
        else # 失效键盘
          bot.answer_callback_query(query.id, text: t("invalid_callback"), show_alert: true)
        end
      end
    end

    macro def_toggle(type_s)
      {{ function_type = type_s.camelcase }}
      sf = get_sf.call FunctionType::{{function_type.id}}
      spawn bot.answer_callback_query(query.id)
      status = sf.status == EnableStatus::TurnOff.value ? EnableStatus::TurnOn : EnableStatus::TurnOff
      sf.update_column(:status, status.value)
      text = t "subfunctions.desc"
      midcall SubfunctionsCommander do
        bot.edit_message_text(
          _chat_id,
           message_id: msg.message_id, 
           text: text, 
           reply_markup: commander.create_markup(_group_id)
        )
      end
    end
  end
end
