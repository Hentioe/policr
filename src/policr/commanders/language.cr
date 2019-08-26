module Policr
  commander Language do
    alias Code = LanguageCode

    def handle(msg, from_nav)
      reply_menu do
        create_menu({
          text:         paste_text,
          reply_markup: paste_markup,
        })
      end
    end

    CHECKED   = "😀 "
    UNCHECKED = ""

    def_text do
      locale = gen_locale _group_id

      t("language.desc", locale: locale)
    end

    def_markup do
      toggle_btn = ->(text : String, name : String) {
        Button.new(text: text, callback_data: "Language:#{name}")
      }

      lang = Model::Language.find_or_create(_group_id, data: {
        chat_id: _group_id.to_i64,
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

      _markup << def_switch "zh_hans"
      _markup << def_switch "zh_hant"
      _markup << def_switch "english"
    end

    private macro def_switch(name)
      [
        toggle_btn.call(make_status.call({{name}}) + t("language.code.{{name.id}}"), {{name}})
      ]
    end
  end
end
