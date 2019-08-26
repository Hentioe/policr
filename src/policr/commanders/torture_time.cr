module Policr
  commander TortureTime do
    def handle(msg, from_nav)
      reply_menu do
        if sended_msg = create_menu({
             text:         create_text(_group_id, _group_name),
             reply_markup: create_markup(_group_id, from_nav: from_nav),
           })
          Cache.carving_torture_time_msg _chat_id, sended_msg.message_id

          sended_msg
        end
      end
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

    def_markup do
      btn = ->(text : String, sec : Int32 | String) {
        Button.new(text: text, callback_data: "TortureTime:#{sec}")
      }
      _markup << def_time_list(btn, [30, 55, 80], TortureTimeType::Sec)
      _markup << def_time_list(btn, [2, 3, 5], TortureTimeType::Min)
      _markup << [btn.call(t("torture.inf_time"), 0)]
    end

    def_text do
      current = t "torture.default_set", {seconds: DEFAULT_TORTURE_SEC}
      if sec = KVStore.get_torture_sec _group_id
        time_len = sec > 0 ? t("units.sec", {n: sec}) : t("units.inf")
        current = t("torture.exists_set", {time_len: time_len})
      end
      t "torture.time_setting", {current_state: current}
    end
  end
end
