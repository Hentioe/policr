module Policr
  callbacker From do
    alias From = Model::From

    def handle(query, msg, data)
      chat_id = msg.chat.id
      from_user_id = query.from.id
      target_id, target_username, chooese = data

      chooese_id = chooese.to_i
      target_user_id = target_id.to_i
      message_id = msg.message_id

      unless from_user_id == target_user_id
        bot.answer_callback_query(query.id, text: t("unrelated_click"), show_alert: true)
        return
      end

      all_from = Array(String).new
      if (from = From.find_by_chat_id(chat_id)) && (from_list = from.gen_list)
        from_list.each do |btn_list|
          btn_list.each { |btn_text| all_from << btn_text }
        end
      end
      bot.edit_message_text(
        chat_id,
        message_id: message_id,
        text: t("from.message", {user_id: target_user_id, from: all_from[chooese_id]?})
      )
    end
  end
end
