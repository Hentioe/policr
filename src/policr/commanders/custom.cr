module Policr
  class CustomCommander < Commander
    def initialize(bot)
      super(bot, "custom")
    end

    def handle(msg)
      role = KVStore.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        bot.send_message msg.chat.id, t("captcha.desc"), reply_to_message_id: msg.message_id, reply_markup: create_markup(msg.chat.id), parse_mode: "markdown"
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end

    CHECKED   = "●"
    UNCHECKED = "○"

    def create_markup(chat_id)
      checked_status = ->(way : Symbol) {
        case way
        when :custom
          KVStore.custom(chat_id) ? CHECKED : UNCHECKED
        when :dynamic
          KVStore.dynamic?(chat_id) ? CHECKED : UNCHECKED
        when :image
          KVStore.enabled_image?(chat_id) ? CHECKED : UNCHECKED
        when :chessboard
          KVStore.enabled_chessboard?(chat_id) ? CHECKED : UNCHECKED
        when :default
          (
            !KVStore.custom(chat_id) &&
            !KVStore.dynamic?(chat_id) &&
            !KVStore.enabled_image?(chat_id) &&
            !KVStore.enabled_chessboard?(chat_id)
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

    def custom_text(chat_id)
      custom_text =
        if custom = custom_tup = KVStore.custom(chat_id)
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
