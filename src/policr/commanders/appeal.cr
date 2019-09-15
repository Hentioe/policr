module Policr
  commander Appeal do
    def handle(msg, from_nav)
      chat_id = msg.chat.id

      bot.delete_message(chat_id, msg.message_id) if chat_id < 0

      user_id =
        if user = msg.from
          user.id
        else
          0
        end

      if Model::Appeal.valid_times(user_id) > 0
        bot.send_message chat_id, "申诉请求被拒绝，因为您已达到申诉次数的上限。"
        return
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
