module Policr
  DEFAULT_DELAY_DELETE = 60*90

  class CleanModeCallback < Callback
    alias DeleteTarget = CleanDeleteTarget

    def initialize(bot)
      super(bot, "CleanMode")
    end

    def handle(query, msg, data)
      target_group do
        chat_id = msg.chat.id
        from_user_id = query.from.id
        name = data[0]

        get_cm = ->(delete_target : DeleteTarget) {
          Model::CleanMode.find_or_create _group_id, delete_target, data: {
            chat_id:       _group_id,
            delete_target: delete_target.value,
            delay_sec:     nil,
            status:        EnableStatus::TurnOff.value,
          }
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
          spawn bot.answer_callback_query(query.id)
          midcall CleanModeCommander do
            bot.edit_message_text(
              chat_id,
              message_id: msg.message_id,
              text: t("clean_mode.desc"),
              reply_markup: commander.create_markup(_group_id)
            )
          end
        else # 失效键盘
          bot.answer_callback_query(query.id, text: t("invalid_callback"), show_alert: true)
        end
      end
    end

    macro def_target(target_s)
      spawn bot.answer_callback_query(query.id)
      {{ delete_target = target_s.camelcase }}
      cm = get_cm.call DeleteTarget::{{delete_target.id}}
      selected = cm.status == EnableStatus::TurnOn.value
      selected ? cm.update_column(:status, EnableStatus::TurnOff.value) : cm.update_column(:status, EnableStatus::TurnOn.value)
      text = t "clean_mode.desc"
      bot.edit_message_text(
        chat_id, 
        message_id: msg.message_id, 
        text: text,
        reply_markup: create_markup(_group_id)
      )
    end

    macro def_delay(target_s)
      {{ delete_target = target_s.camelcase }}
      spawn bot.answer_callback_query(query.id)
      cm = get_cm.call DeleteTarget::{{delete_target.id}}
      Cache.carving_clean_mode_time_msg chat_id, msg.message_id, {cm, DeleteTarget::{{delete_target.id}}}

      bot.edit_message_text(
        chat_id, 
        message_id: msg.message_id, 
        text: create_time_setting_text(_group_id, DeleteTarget::{{delete_target.id}}, model: cm), 
        reply_markup: create_time_setting_markup(_group_id, DeleteTarget::{{delete_target.id}})
      )
    end

    def create_markup(group_id)
      midcall CleanModeCommander do
        commander.create_markup(group_id)
      end
    end

    def create_time_setting_text(group_id, delete_target, model : Model::CleanMode? = nil)
      cm = model || Model::CleanMode.find_or_create group_id, delete_target, data: {
        chat_id:       group_id,
        delete_target: delete_target.value,
        delay_sec:     nil,
        status:        EnableStatus::TurnOff.value,
      }
      sec = cm.delay_sec || DEFAULT_DELAY_DELETE
      delete_target_s =
        case delete_target
        when DeleteTarget::TimeoutVerified
          "timeout_verified"
        when DeleteTarget::WrongVerified
          "wrong_verified"
        when DeleteTarget::Welcome
          "welcome"
        when DeleteTarget::From
          "from"
        else
          "unknown"
        end
      text = t("clean_mode.delay_setting", {
        target: t("clean_mode.#{delete_target_s}"),
        hor:    (sec.to_f / 3600).round(2),
      })
    end

    BACK_SYMBOL = "«"

    def create_time_setting_markup(group_id, delete_target)
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
