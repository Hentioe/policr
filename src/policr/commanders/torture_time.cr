module Policr
  class TortureTimeCommander < Commander
    def initialize(bot)
      super(bot, "torture_time")
    end

    def handle(msg)
      reply_menu do
        if send_message = bot.send_message(
             _chat_id,
             text: create_text(_group_id, _group_name),
             reply_to_message_id: _reply_msg_id,
             reply_markup: create_markup
           )
          Cache.carving_torture_time_msg _chat_id, send_message.message_id

          send_message
        end
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

    def_text do
      current = t "torture.default_set", {seconds: DEFAULT_TORTURE_SEC}
      if sec = KVStore.get_torture_sec _group_id
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
