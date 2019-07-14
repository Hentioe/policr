module Policr
  class TortureTimeCommander < Commander
    def initialize(bot)
      super(bot, "torture_time")
    end

    def handle(msg)
      role = KVStore.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        chat_id = msg.chat.id

        if send_message = bot.send_message msg.chat.id, text(msg.chat.id), reply_to_message_id: msg.message_id, disable_web_page_preview: true, parse_mode: "markdown", reply_markup: create_markup
          Cache.carving_torture_time_msg chat_id, send_message.message_id
        end
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end

    def create_markup
      markup = Markup.new
      btn = ->(text : String, sec : Int32 | String) {
        Button.new(text: text, callback_data: "TortureTime:#{sec}")
      }
      markup << def_time_list(btn, [30, 55, 80], TortureTimeType::Sec)
      markup << def_time_list(btn, [2, 3, 5], TortureTimeType::Min)
      markup << [btn.call(t("torture.inf_time"), 0)]
      markup
    end

    def text(chat_id)
      current = t "torture.default_set", {seconds: DEFAULT_TORTURE_SEC}
      if sec = KVStore.get_torture_sec chat_id
        time_len = sec > 0 ? t("units.sec", {n: sec}) : t("units.inf")
        current = t("torture.exists_set", {time_len: time_len})
      end
      t "torture.time_setting", {current_state: current}
    end

    macro def_time_list(btn_proc, list, unit)
      [
      {% for t in list %}
        {% if unit.resolve == TortureTimeType::Sec %}
          {{btn_proc}}.call(t("units.sec", {n: {{t}}}), {{t}}),
        {% elsif unit.resolve == TortureTimeType::Min %}
          {{btn_proc}}.call(t("units.min", {n: {{t}}}), {{t*60}}),
        {% end %}
      {% end %}
      ]
    end
  end
end
