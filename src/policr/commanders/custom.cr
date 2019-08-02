module Policr
  commander Custom do
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

    def_text do
      t("captcha.desc")
    end

    CHECKED   = "●"
    UNCHECKED = "○"

    def create_markup(group_id)
      checked_status = ->(way : Symbol) {
        case way
        when :custom
          KVStore.custom(group_id) ? CHECKED : UNCHECKED
        when :dynamic
          KVStore.enabled_dynamic_captcha?(group_id) ? CHECKED : UNCHECKED
        when :image
          KVStore.enabled_image_captcha?(group_id) ? CHECKED : UNCHECKED
        when :chessboard
          KVStore.enabled_chessboard_captcha?(group_id) ? CHECKED : UNCHECKED
        when :default
          (
            !KVStore.custom(group_id) &&
            !KVStore.enabled_dynamic_captcha?(group_id) &&
            !KVStore.enabled_image_captcha?(group_id) &&
            !KVStore.enabled_chessboard_captcha?(group_id)
          ) ? CHECKED : UNCHECKED
        else
          UNCHECKED
        end
      }

      markup = Markup.new
      btn = ->(text : String, item : String) {
        Button.new(text: text, callback_data: "Custom:#{item}")
      }

      make_text = ->(name : Symbol) {
        "#{checked_status.call(name)} #{t("captcha.names.#{name.to_s}")}"
      }
      default_text = make_text.call :default
      custom_text = make_text.call :custom
      dynamic_text = make_text.call :dynamic
      image_text = make_text.call :image
      chessboard_text = make_text.call :chessboard

      markup << [btn.call(default_text, "default")]
      markup << [btn.call(custom_text, "custom")]
      markup << [btn.call(dynamic_text, "dynamic")]
      markup << [btn.call(image_text, "image")]
      markup << [btn.call(chessboard_text, "chessboard")]
      markup
    end

    def_text custom_text do
      custom_text =
        if custom = custom_tup = KVStore.custom(_group_id)
          true_indices, title, answers = custom_tup
          String.build do |str|
            str << title
            str << "\n"
            answers.map_with_index do |ans_line, i|
              status_sym = true_indices.includes?(i + 1) ? "√" : "×"
              str << "#{status_sym} #{ans_line}"
              str << "\n" if i < (answers.size - 1)
            end
          end
        else
          t "custom.none"
        end
      t "custom.desc", {custom_text: custom_text}
    end
  end
end
