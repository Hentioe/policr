module Policr
  class MaxLengthCallback < Callback
    def initialize(bot)
      super(bot, "MaxLength")
    end

    def handle(query, msg, data)
      chat_id = msg.chat.id
      from_user_id = query.from.id
      size_s = data[0]

      # 检测权限
      role = KVStore.trust_admin?(msg.chat.id) ? :admin : :creator
      unless (user = msg.from) && bot.has_permission?(msg.chat.id, from_user_id, role)
        bot.answer_callback_query(query.id, text: t("callback.no_permission"), show_alert: true)
        return
      end

      size = size_s[0...(size_s.size - 1)].to_i

      if size_s.ends_with?("t")
        Model::MaxLength.update_total(chat_id, size)
      elsif size_s.ends_with?("r")
        Model::MaxLength.update_rows(chat_id, size)
      else
        bot.answer_callback_query(query.id, text: t("max_length.invalid_value", {size: size_s}))
        return
      end

      spawn bot.answer_callback_query(query.id)
      bot.edit_message_text(
        msg.chat.id,
        message_id: msg.message_id,
        text: text(msg.chat.id),
        reply_markup: markup(chat_id)
      )
    end

    def text(chat_id)
      midcall StrictModeCallback do
        _callback.create_max_length_text(chat_id)
      end
    end

    def markup(chat_id)
      midcall StrictModeCallback do
        _callback.create_max_length_markup(chat_id)
      end
    end
  end
end
