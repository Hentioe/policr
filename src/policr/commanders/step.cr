module Policr
  class StepCommander < Commander
    def initialize(bot)
      super(bot, "step")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        bot.send_message msg.chat.id, t("step.desc"), reply_to_message_id: msg.message_id, reply_markup: create_markup(msg.chat.id), parse_mode: "markdown"
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end

    MORE_SYMBOL = "»"
    SELECTED    = "■"
    UNSELECTED  = "□"

    def create_markup(chat_id)
      btn = ->(text : String, name : String) {
        Button.new(text: text, callback_data: "Step:#{name}")
      }
      force_multiple_symbol = ->{
        DB.force_multiple?(chat_id) ? SELECTED : UNSELECTED
      }
      markup = Markup.new
      markup << [btn.call("#{force_multiple_symbol.call} #{t("step.force_multiple")}", "force_multiple")]
      markup << [btn.call("#{t("step.more_count_settings")} #{MORE_SYMBOL}", "more_count_settings"),
                 btn.call("#{t("step.more_accuracy_settings")} #{MORE_SYMBOL}", "more_accuracy_settings")]

      markup
    end
  end
end
