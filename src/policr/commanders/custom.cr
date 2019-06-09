module Policr
  class CustomCommander < Commander
    def initialize(bot)
      super(bot, "custom")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        bot.send_message msg.chat.id, t("custom.desc"), reply_to_message_id: msg.message_id, reply_markup: create_markup(msg.chat.id), parse_mode: "markdown"
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end

    CHECKED   = "◉"
    UNCHECKED = "◎"

    def create_markup(chat_id)
      checked_status = ->(way : Symbol) {
        case way
        when :custom
          DB.custom(chat_id) ? CHECKED : UNCHECKED
        when :dynamic
          DB.dynamic?(chat_id) ? CHECKED : UNCHECKED
        when :default
          (!DB.custom(chat_id) && !DB.dynamic?(chat_id)) ? CHECKED : UNCHECKED
        else
          UNCHECKED
        end
      }

      markup = Markup.new
      btn = ->(text : String, item : String) {
        Button.new(text: text, callback_data: "Custom:#{item}")
      }
      markup << [btn.call("#{checked_status.call(:default)} 默认验证", "default")]
      markup << [btn.call("#{checked_status.call(:custom)} 定制验证", "custom")]
      markup << [btn.call("#{checked_status.call(:dynamic)} 动态验证", "dynamic")]
      markup
    end
  end
end
