module Policr
  commander Template do
    def handle(msg, from_nav)
      reply_menu do
        sended_msg = create_menu({
          text:         paste_text,
          reply_markup: paste_markup,
        })

        if sended_msg
          Cache.carving_template_setting_msg _chat_id, sended_msg.message_id
        end

        sended_msg
      end
    end

    def_text do
      content =
        if t = Model::Template.exists? _group_id
          t.content
        else
          t "none"
        end
      t "template.desc", {content: content}
    end

    SELECTED   = "■"
    UNSELECTED = "□"

    def_markup do
      select_status = Model::Template.enabled?(_group_id) ? SELECTED : UNSELECTED

      make_btn = ->(text : String, name : String) {
        Button.new(text: text, callback_data: "Template:#{name}:toggle")
      }

      _markup << [make_btn.call(select_status + " " + t("template.enable"), "enable")]
    end
  end
end
