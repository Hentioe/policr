module Policr
  class StrictModeCallback < Callback
    alias EnableStatus = Policr::EnableStatus
    alias DeleteTarget = Policr::CleanDeleteTarget

    def initialize(bot)
      super(bot, "StrictMode")
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

      case name
      when "max_length"
        unless Model::MaxLength.exists?(chat_id)
          bot.answer_callback_query(query.id, text: t("strict_mode.mission_settings"))
          return
        end
      when "content_blocked"
      when "max_length_setting"
        bot.edit_message_text chat_id, message_id: msg.message_id, text: t("max_length.desc"), reply_markup: create_max_length_markup(chat_id)
      when "back"
        midcall StrictModeCommander do
          bot.edit_message_text chat_id, message_id: msg.message_id, text: t("strict_mode.desc"), reply_markup: commander.create_markup(chat_id), parse_mode: "markdown"
        end
      else # 失效键盘
        bot.answer_callback_query(query.id, text: t("invalid_callback"), show_alert: true)
      end
    end

    BACK_SYMBOL = "«"

    def create_max_length_markup(chat_id)
      markup = Markup.new

      make_btn = ->(text : String, size : String) {
        Button.new(text: text, callback_data: "MaxLength:#{size}")
      }

      markup << def_length_list(make_btn, [300, 350, 400, 500], "total")
      rows_line = [Button.new(text: BACK_SYMBOL, callback_data: "StrictMode:back")]
      rows_line += def_length_list(make_btn, [15, 20, 25, 30], "rows")
      markup << rows_line

      markup
    end

    macro def_length_list(make_btn, list, type_s)
      [
      {% for c in list %}
        {% if type_s == "total" %}
          {{make_btn}}.call(t("units.wor", {n: {{c}}}), {{"#{c}t"}}),
        {% elsif type_s == "rows" %}
          {{make_btn}}.call(t("units.row", {n: {{c}}}), {{"#{c}r"}}),
        {% end %}
      {% end %}
      ]
    end
  end
end
