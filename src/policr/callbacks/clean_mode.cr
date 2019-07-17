module Policr
  DEFAULT_DELAY_DELETE = 60*90

  class CleanModeCallback < Callback
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
        def_target "timeout_verified"
      when "wrong_verified"
        def_target "wrong_verified"
      when "welcome"
        def_target "welcome"
      when "from"
        def_target "from"
      when "timeout_verified_delay_time"
        def_delay "timeout_verified"
      when "wrong_verified_delay_time"
        def_delay "wrong_verified"
      when "welcome_delay_time"
        def_delay "welcome"
      when "from_delay_time"
        def_delay "from"
      when "back"
        midcall CleanModeCommander do
          bot.edit_message_text(
            chat_id,
            message_id: msg.message_id,
            text: t("clean_mode.desc"),
            reply_markup: commander.create_markup(chat_id)
          )
        end
      else # 失效键盘
        bot.answer_callback_query(query.id, text: t("invalid_callback"), show_alert: true)
      end
    end

    macro def_target(target_s)
      {{ delete_target = target_s.camelcase }}
      cm = get_cm.call DeleteTarget::{{delete_target.id}}
      selected = cm.status == EnableStatus::TurnOn.value
      selected ? cm.update_column(:status, EnableStatus::TurnOff.value) : cm.update_column(:status, EnableStatus::TurnOn.value)
      text = t "clean_mode.desc"
      spawn bot.answer_callback_query(query.id)
      bot.edit_message_text(
        chat_id, 
        message_id: msg.message_id, 
        text: text,
        reply_markup: create_markup(chat_id)
      )
    end

    macro def_delay(target_s)
      {{ delete_target = target_s.camelcase }}
      cm = get_cm.call DeleteTarget::{{delete_target.id}}
      sec = cm.delay_sec || DEFAULT_DELAY_DELETE
      text = t "clean_mode.delay_setting", {target: t("clean_mode.{{target_s.id}}"), hor: (sec.to_f / 3600).round(2)}
      bot.edit_message_text(
        chat_id, 
        message_id: msg.message_id, 
        text: text, 
        reply_markup: create_time_setting_markup(chat_id, DeleteTarget::{{delete_target.id}})
      )
    end

    # macro def_change
    #   (selected ? t("settings.unselected") : t("settings.selected")) + t("settings.#{name}")
    # end

    def create_markup(chat_id)
      midcall CleanModeCommander do
        commander.create_markup(chat_id)
      end
    end

    BACK_SYMBOL = "«"

    def create_time_setting_markup(chat_id, delete_target)
      markup = Markup.new

      btn = ->(text : String, sec : Int32 | String) {
        Button.new(text: text, callback_data: "DelayTime:#{delete_target.value}:#{sec}")
      }
      markup << def_time_list(btn, [15, 30, 45], TimeUnit::Min)
      hors = [Button.new(text: BACK_SYMBOL, callback_data: "CleanMode:back")]
      hors += def_time_list(btn, [1, 2, 6], TimeUnit::Hour)
      markup << hors

      markup
    end

    macro def_time_list(btn_proc, list, unit)
      [
      {% for t in list %}
        {% if unit.resolve == TimeUnit::Min %}
          {{btn_proc}}.call(t("units.min", {n: {{t}}}), {{t*60}}),
        {% elsif unit.resolve == TimeUnit::Hour %}
          {{btn_proc}}.call(t("units.hor", {n: {{t}}}), {{t*60*60}}),
        {% end %}
      {% end %}
      ]
    end
  end
end
