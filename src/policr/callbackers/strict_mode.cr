module Policr
  callbacker StrictMode do
    MAX_RULE_LENGTH = 26

    def handle(query, msg, data)
      target_group do
        name = data[0]

        msg_id = msg.message_id

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
            text: back_text(_group_id, _group_name),
            reply_markup: markup(_group_id)
          )
        when "content_blocked"
          if Model::BlockContent.enabled?(_group_id) # 禁用全部内容屏蔽蔽规则
            Model::BlockContent.disable_all(_group_id)
          else
            bot.answer_callback_query(query.id, text: t("strict_mode.missing_settings"))
            return
          end
          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: back_text(_group_id, _group_name),
            reply_markup: markup(_group_id)
          )
        when "format_limit"
          if fl = Model::FormatLimit.find(_group_id) # 删除文件格式限制
            Model::FormatLimit.delete(fl.id)
          else
            bot.answer_callback_query(query.id, text: t("strict_mode.missing_settings"))
            return
          end
          bot.edit_message_text(
            _chat_id,
            message_id: msg_id,
            text: back_text(_group_id, _group_name),
            reply_markup: markup(_group_id)
          )
        when "max_length_setting"
          Cache.carving_max_length_msg _chat_id, msg.message_id
          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: create_max_length_text(_group_id, _group_name),
            reply_markup: create_max_length_markup(_group_id)
          )
        when "content_blocked_setting"
          # 标记设置消息
          Cache.carving_blocked_content_msg _chat_id, msg.message_id
          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: create_content_blocked_text(_group_id, _group_name),
            reply_markup: create_content_blocked_markup(_group_id)
          )
        when "format_limit_setting"
          Cache.carving_format_limit_msg _chat_id, msg.message_id
          bot.edit_message_text(
            _chat_id,
            message_id: msg.message_id,
            text: create_format_limit_text(_group_id, _group_name),
            reply_markup: create_format_limit_markup(_group_id)
          )
        when "back"
          midcall StrictModeCommander do
            spawn bot.answer_callback_query(query.id)
            bot.edit_message_text(
              _chat_id,
              message_id: msg.message_id,
              text: back_text(_group_id, _group_name),
              reply_markup: _commander.create_markup(_group_id)
            )
          end
        else # 失效键盘
          bot.answer_callback_query(query.id, text: t("invalid_callback"), show_alert: true)
        end
      end
    end

    def back_text(group_id, group_name)
      midcall StrictModeCommander do
        _commander.create_text group_id, group_name
      end
    end

    BACK_SYMBOL     = "«"
    BIG_BACK_SYMBOL = "返回"
    DATE_FORMAT     = "%Y-%m-%d %H:%M:%S"

    def_text create_content_blocked_text do
      handler = "\n\n"
      rules_content =
        if (list = Model::BlockContent.load_list _group_id) && list.size > 0
          sb = String.build do |str|
            list.each_with_index do |bc, i|
              str << "#{i + 1}."
              str << " [已启用]" if bc.is_enabled
              str << " [已禁用]" unless bc.is_enabled
              str << "[#{bc.alias_s}](https://t.me/#{bot.username}?start=rule_#{bc.id})"
            end
          end
        else
          t "none"
        end
      t "content_blocked.desc", {rules_content: rules_content, time: Time.now.to_s(DATE_FORMAT)}
    end

    def create_content_blocked_markup(group_id)
      markup = Markup.new

      markup << [Button.new(text: "刷新", callback_data: "StrictMode:content_blocked_setting")]
      markup << [Button.new(text: BIG_BACK_SYMBOL, callback_data: "StrictMode:back")]

      markup
    end

    def_text create_max_length_text do
      total, rows = Model::MaxLength.values(_group_id)
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

    BACK_BTN = Button.new(text: BACK_SYMBOL, callback_data: "StrictMode:back")

    def_text create_format_limit_text do
      list = Model::FormatLimit.get_format_list _group_id
      list_s = list.size > 0 ? list.map { |extension_name| ".#{extension_name}" }.join(" | ") : t("none")
      t "format_limit.desc", {list: list_s}
    end

    SELECTED   = "■"
    UNSELECTED = "□"

    def_markup create_format_limit_markup do
      make_btn = ->(extension_name : String) {
        status = Model::FormatLimit.includes?(_group_id, extension_name) ? SELECTED : UNSELECTED
        Button.new(text: "#{status} .#{extension_name}", callback_data: "FormatLimit:#{extension_name}:toggle")
      }
      _markup << def_format_list(["exe", "com", "bat"])
      _markup << [BACK_BTN] + def_format_list(["sh", "ps1"])
    end

    private macro def_format_list(list)
      [
        {% for extension_name in list %}
          make_btn.call({{extension_name}}),
        {% end %}
      ]
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
