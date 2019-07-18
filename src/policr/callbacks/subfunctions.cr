module Policr
  class SubfunctionsCallback < Callback
    alias FunctionType = SubfunctionType

    def initialize(bot)
      super(bot, "Subfunctions")
    end

    def handle(query, msg, data)
      chat_id = msg.chat.id
      from_user_id = query.from.id
      type_value, _ = data

      # 检测权限
      role = KVStore.enabled_trust_admin?(msg.chat.id) ? :admin : :creator
      unless (user = msg.from) && bot.has_permission?(msg.chat.id, from_user_id, role)
        bot.answer_callback_query(query.id, text: t("callback.no_permission"), show_alert: true)
        return
      end

      get_sf = ->(function_type : FunctionType) {
        sf = Model::Subfunction.where { (_chat_id == chat_id) & (_type == function_type.value) }.first
        sf = sf || Model::Subfunction.create!({
          chat_id: chat_id,
          type:    function_type.value,
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

    macro def_toggle(type_s)
      {{ function_type = type_s.camelcase }}
      sf = get_sf.call FunctionType::{{function_type.id}}
      spawn bot.answer_callback_query(query.id)
      status = sf.status == EnableStatus::TurnOff.value ? EnableStatus::TurnOn : EnableStatus::TurnOff
      sf.update_column(:status, status.value)
      text = t "subfunctions.desc"
      midcall SubfunctionsCommander do
        bot.edit_message_text(
          chat_id,
           message_id: msg.message_id, 
           text: text, 
           reply_markup: commander.create_markup(chat_id)
        )
      end
    end
  end
end
