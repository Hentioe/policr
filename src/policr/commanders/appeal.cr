module Policr
  commander Appeal do
    def handle(msg)
      chat_id = msg.chat.id

      bot.delete_message(msg.chat.id, msg.message_id) if chat_id < 0

      user_id =
        if user = msg.from
          user.id
        else
          0
        end

      count =
        if list = Model::Report.all_valid(user_id)
          list.size
        else
          0
        end

      bot.send_message(
        chat_id: chat_id,
        text: create_text(count),
        reply_markup: create_markup(count),
      )
    end

    def create_text(count)
      if count > 0
        t("appeal.desc", {count: count})
      else
        t("appeal.non_blacklist")
      end
    end

    def create_markup(count)
      return unless count > 0
      markup = Markup.new
      markup << [Button.new(text: t("appeal.start"), callback_data: "Appeal:start")]

      markup
    end
  end
end
