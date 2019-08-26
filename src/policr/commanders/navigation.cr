module Policr
  commander Navigation do
    def handle(msg, from_nav)
      reply_menu do
        create_menu({
          text:         paste_text,
          reply_markup: create_markup(_group_id, from_nav: false),
        })
      end
    end

    def_markup do
      make_btn = ->(feature : String) {
        Button.new(text: t("navigation.feature.#{feature}"), callback_data: "Navigation:#{feature}")
      }
      _markup << [make_btn.call("base_setting"), make_btn.call("subfunctions")]
      _markup << [make_btn.call("custom"), make_btn.call("torture_time")]
      _markup << [make_btn.call("from"), make_btn.call("welcome")]
      _markup << [make_btn.call("clean_mode"), make_btn.call("strict_mode")]
      _markup << [make_btn.call("anti_service_msg"), make_btn.call("template")]
      _markup << [make_btn.call("language")]
    end

    def_text do
      t "navigation.desc"
    end
  end
end
