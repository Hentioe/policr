module Policr
  class StrictModeCallback < Callback
    MAX_RULE_LENGTH = 26

    def initialize(bot)
      super(bot, "StrictMode")
    end

    def handle(query, msg, data)
      target_group do
        name = data[0]

        case name
        when "max_length"
          if ml = Model::MaxLength.find(_group_id) # 删除长度限制
            Model::MaxLength.delete(ml.id)
          else
            bot.answer_callback_query(query.id, text: t("strict_mode.missing_settings"))
            return
          end
          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: t("strict_mode.desc"),
            reply_markup: markup(_group_id)
          )
        when "content_blocked"
          if bc = Model::BlockContent.find(_group_id) # 删除内容屏蔽规则
            Model::BlockContent.delete(bc.id)
          else
            bot.answer_callback_query(query.id, text: t("strict_mode.missing_settings"))
            return
          end
          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: t("strict_mode.desc"),
            reply_markup: markup(_group_id)
          )
        when "max_length_setting"
          Cache.carving_max_length_msg _chat_id, msg.message_id
          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: create_max_length_text(_group_id),
            reply_markup: create_max_length_markup(_group_id)
          )
        when "content_blocked_setting"
          # 标记设置消息
          Cache.carving_blocked_content_msg _chat_id, msg.message_id
          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: create_content_blocked_text(_group_id),
            reply_markup: create_content_blocked_markup(_group_id)
          )
        when "back"
          midcall StrictModeCommander do
            bot.edit_message_text(
              _chat_id,
              message_id: msg.message_id,
              text: t("strict_mode.desc"),
              reply_markup: commander.create_markup(_group_id)
            )
          end
        else # 失效键盘
          bot.answer_callback_query(query.id, text: t("invalid_callback"), show_alert: true)
        end
      end
    end

    BACK_SYMBOL     = "«"
    BIG_BACK_SYMBOL = "🔙"

    def create_content_blocked_text(group_id)
      rule =
        if bc = Model::BlockContent.find(group_id)
          bc.expression
        else
          t("content_blocked.none")
        end
      t "content_blocked.desc", {size: MAX_RULE_LENGTH, rule: rule}
    end

    def create_content_blocked_markup(group_id)
      markup = Markup.new

      markup << [Button.new(text: BIG_BACK_SYMBOL, callback_data: "StrictMode:back")]

      markup
    end

    def create_max_length_text(group_id)
      total, rows = Model::MaxLength.values(group_id)
      t "max_length.desc", {total: total || t("max_length.none"), rows: rows || t("max_length.none")}
    end

    def create_max_length_markup(group_id)
      markup = Markup.new

      make_btn = ->(text : String, size : String) {
        Button.new(text: text, callback_data: "MaxLength:#{size}")
      }

      markup << def_length_list(make_btn, [200, 250, 300, 350], "total")
      rows_line = [Button.new(text: BACK_SYMBOL, callback_data: "StrictMode:back")]
      rows_line += def_length_list(make_btn, [10, 12, 15, 20], "rows")
      markup << rows_line

      markup
    end

    def markup(group_id)
      midcall StrictModeCommander do
        _commander.create_markup group_id
      end
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
