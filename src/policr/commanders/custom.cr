module Policr
  class CustomCommander < Commander
    def initialize(bot)
      super(bot, "custom")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
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
          DB.custom(chat_id) ? CHECKED : UNCHECKED
        when :dynamic
          DB.dynamic?(chat_id) ? CHECKED : UNCHECKED
        when :image
          DB.enabled_image?(chat_id) ? CHECKED : UNCHECKED
        when :default
          (!DB.custom(chat_id) && !DB.dynamic?(chat_id) && !DB.enabled_image?(chat_id)) ? CHECKED : UNCHECKED
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

      markup << [btn.call(default_text, "default")]
      markup << [btn.call(custom_text, "custom")]
      markup << [btn.call(dynamic_text, "dynamic")]
      markup << [btn.call(image_text, "image")]
      markup
    end
  end
end
