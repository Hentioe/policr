module Policr
  commander Welcome do
    alias Welcome = Model::Welcome

    def handle(msg, from_nav)
      reply_menu do
        sended_msg = create_menu({
          text:         paste_text,
          reply_markup: paste_markup,
        })

        if sended_msg
          Cache.carving_welcome_setting_msg _chat_id, sended_msg.message_id
        end

        sended_msg
      end
    end

    def_text do
      welcome_text, sticker_file_id =
        if welcome = Welcome.find_by_chat_id(_group_id)
          {welcome.content, welcome.sticker_file_id || t("none")}
        else
          {t("none"), t("none")}
        end

      t("welcome.hint", {welcome_text: welcome_text, sticker_file_id: sticker_file_id})
    end

    SELECTED   = "■"
    UNSELECTED = "□"

    def_markup do
      make_status = ->(name : String) {
        case name
        when "link_preview"
          Welcome.link_preview_enabled?(_group_id) ? SELECTED : UNSELECTED
        when "sticker_mode"
          Welcome.sticker_mode_enabled?(_group_id) ? SELECTED : UNSELECTED
        when "enable"
          Welcome.enabled?(_group_id) ? SELECTED : UNSELECTED
        when "timing_delete"
          cm = Model::CleanMode.where {
            (_chat_id == _group_id) &
              (_delete_target == CleanDeleteTarget::Welcome.value)
          }.first

          if cm
            cm.status == EnableStatus::TurnOn.value ? SELECTED : UNSELECTED
          else
            UNSELECTED
          end
        when "intelligent_delete"
          # 待检测状态
          UNSELECTED
        else
          UNSELECTED
        end
      }
      make_btn = ->(text : String, name : String) {
        Button.new(text: text, callback_data: "Welcome:#{name}")
      }

      _markup << def_btn_list ["enable", "sticker_mode", "link_preview"]
      _markup << def_btn_list ["timing_delete", "intelligent_delete"]
    end

    macro def_btn_list(list)
      [
      {% for name in list %}
        make_btn.call(make_status.call({{name}}) + " " + t("welcome.{{name.id}}"), {{name}}),
      {% end %}
      ]
    end
  end
end
