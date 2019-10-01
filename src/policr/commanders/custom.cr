module Policr
  commander Custom do
    alias VerificationMode = Model::VerificationMode

    def handle(msg, from_nav)
      reply_menu do
        create_menu({
          text:         create_text(_group_id, _group_name),
          reply_markup: create_markup(_group_id, from_nav: from_nav),
        })
      end
    end

    def_text do
      t("captcha.desc")
    end

    CHECKED   = "●"
    UNCHECKED = "○"

    def_markup do
      mode = VerificationMode.get_mode _group_id, VeriMode::Default

      checked_status = ->(way : Symbol) {
        case way
        when :custom
          mode == VeriMode::Custom ? CHECKED : UNCHECKED
        when :dynamic
          mode == VeriMode::Arithmetic ? CHECKED : UNCHECKED
        when :image
          mode == VeriMode::Image ? CHECKED : UNCHECKED
        when :chessboard
          mode == VeriMode::Chessboard ? CHECKED : UNCHECKED
        when :default
          mode == VeriMode::Default ? CHECKED : UNCHECKED
        else
          UNCHECKED
        end
      }

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

      _markup << [btn.call(default_text, "default")]
      _markup << [btn.call(custom_text, "custom")]
      _markup << [btn.call(dynamic_text, "dynamic")]
      _markup << [btn.call(image_text, "image")]
      _markup << [btn.call(chessboard_text, "chessboard")]
    end

    def_text custom_text do
      custom_text =
        if Model::VerificationMode.is?(_group_id, VeriMode::Custom) &&
           (suite = Model::QASuite.find_by_chat_id _group_id)
          title = suite.title
          true_indices, answers = suite.gen_answers
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
