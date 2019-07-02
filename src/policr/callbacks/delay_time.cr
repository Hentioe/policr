module Policr
  class DelayTimeCallback < Callback
    alias EnableStatus = Policr::EnableStatus
    alias DeleteTarget = Policr::CleanDeleteTarget

    def initialize(bot)
      super(bot, "DelayTime")
    end

    def handle(query, msg, data)
      chat_id = msg.chat.id
      from_user_id = query.from.id
      delete_target_value, sec = data
      sec = sec.to_i

      # 检测权限
      role = KVStore.trust_admin?(msg.chat.id) ? :admin : :creator
      unless (user = msg.from) && bot.has_permission?(msg.chat.id, from_user_id, role)
        bot.answer_callback_query(query.id, text: t("callback.no_permission"), show_alert: true)
        return
      end

      get_cm = ->(delete_target : DeleteTarget) {
        cm = Model::CleanMode.where { (_chat_id == chat_id) & (_delete_target == delete_target.value) }.first
        cm = cm || Model::CleanMode.create!({
          chat_id:       chat_id,
          delete_target: delete_target.value,
          delay_sec:     nil,
          status:        EnableStatus::TurnOff.value,
        })
      }

      case DeleteTarget.new(delete_target_value.to_i)
      when DeleteTarget::TimeoutVerified
        def_target "timeout_verified"
      when DeleteTarget::WrongVerified
        def_target "wrong_verified"
      when DeleteTarget::Welcome
        def_target "welcome"
      when DeleteTarget::From
        def_target "from"
      else # 失效键盘
        bot.answer_callback_query(query.id, text: t("invalid_callback"), show_alert: true)
      end
    end

    macro def_target(target_s)
      {{ delete_target = target_s.camelcase }}
      cm = get_cm.call DeleteTarget::{{delete_target.id}}
      spawn bot.answer_callback_query(query.id)
      cm.update_column(:delay_sec, sec)
      text = t "clean_mode.delay_setting", {target: t("clean_mode.{{target_s.id}}"), hor: (sec.to_f / 3600).round(2)}
      midcall CleanModeCallback do
        bot.edit_message_text chat_id: chat_id, message_id: msg.message_id, text: text, disable_web_page_preview: true, parse_mode: "markdown", reply_markup: callback.create_time_setting_markup(chat_id, DeleteTarget::{{delete_target.id}})
      end
    end
  end
end
