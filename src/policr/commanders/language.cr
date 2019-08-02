module Policr
  commander Language do
    alias Code = LanguageCode

    def handle(msg)
      reply_menu do
        bot.send_message(
          _chat_id,
          text: create_text(_group_id, _group_name),
          reply_to_message_id: _reply_msg_id,
          reply_markup: create_markup(_group_id)
        )
      end
    end

    CHECKED   = "😀 "
    UNCHECKED = ""

    def_text do
      locale = gen_locale _group_id

      t("language.desc", locale: locale)
    end

    def create_markup(group_id)
      toggle_btn = ->(text : String, name : String) {
        Button.new(text: text, callback_data: "Language:#{name}")
      }

      lang = Model::Language.find_or_create(group_id, data: {
        chat_id: group_id.to_i64,
        code:    Code::ZhHans.value,
        auto:    EnableStatus::TurnOff.value,
      })

      make_status = ->(code_name : String) {
        case code_name
        when "zh_hans"
          lang.code == Code::ZhHans.value ? CHECKED : UNCHECKED
        when "zh_hant"
          lang.code == Code::ZhHant.value ? CHECKED : UNCHECKED
        when "english"
          lang.code == Code::English.value ? CHECKED : UNCHECKED
        else
          UNCHECKED
        end
      }

      markup = Markup.new
      markup << def_switch "zh_hans"
      markup << def_switch "zh_hant"
      markup << def_switch "english"

      markup
    end

    private macro def_switch(name)
      [
        toggle_btn.call(make_status.call({{name}}) + t("language.code.{{name.id}}"), {{name}})
      ]
    end
  end
end
