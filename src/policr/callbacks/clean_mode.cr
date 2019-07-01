module Policr
  DEFAULT_DELAY_DELETE = 60*90

  class CleanModeCallback < Callback
    alias EnableStatus = Policr::EnableStatus
    alias DeleteTarget = Policr::CleanDeleteTarget

    def initialize(bot)
      super(bot, "CleanMode")
    end

    def handle(query, msg, data)
      chat_id = msg.chat.id
      from_user_id = query.from.id
      name = data[0]

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

      case name
      when "timeout_verified"
        cm = get_cm.call DeleteTarget::TimeoutVerified
        selected = cm.status == EnableStatus::TurnOn.value
        selected ? cm.update_column(:status, EnableStatus::TurnOff.value) : cm.update_column(:status, EnableStatus::TurnOn.value)
        text = t "clean_mode.desc"
        spawn bot.answer_callback_query(query.id)
        bot.edit_message_text chat_id: chat_id, message_id: msg.message_id, text: text, disable_web_page_preview: true, parse_mode: "markdown", reply_markup: create_markup(chat_id)
      when "wrong_verified"
        cm = get_cm.call DeleteTarget::WrongVerified
        selected = cm.status == EnableStatus::TurnOn.value
        selected ? cm.update_column(:status, EnableStatus::TurnOff.value) : cm.update_column(:status, EnableStatus::TurnOn.value)
        text = t "clean_mode.desc"
        spawn bot.answer_callback_query(query.id)
        bot.edit_message_text chat_id: chat_id, message_id: msg.message_id, text: text, disable_web_page_preview: true, parse_mode: "markdown", reply_markup: create_markup(chat_id)
      when "timeout_delay_time"
        bot.answer_callback_query(query.id, text: t("clean_mode.not_implemented"), show_alert: true)
      when "wrong_delay_time"
        bot.answer_callback_query(query.id, text: t("clean_mode.not_implemented"), show_alert: true)
      else # 失效键盘
        bot.answer_callback_query(query.id, text: t("invalid_callback"), show_alert: true)
      end
    end

    # macro def_change
    #   (selected ? t("settings.unselected") : t("settings.selected")) + t("settings.#{name}")
    # end

    def create_markup(chat_id)
      midcall CleanModeCommander do
        commander.create_markup(chat_id)
      end
    end
  end
end
