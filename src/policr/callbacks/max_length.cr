module Policr
  class MaxLengthCallback < Callback
    def initialize(bot)
      super(bot, "MaxLength")
    end

    def handle(query, msg, data)
      target_group do
        size_s = data[0]

        size = size_s[0...(size_s.size - 1)].to_i

        if size_s.ends_with?("t")
          Model::MaxLength.update_total(_group_id, size)
        elsif size_s.ends_with?("r")
          Model::MaxLength.update_rows(_group_id, size)
        else
          bot.answer_callback_query(query.id, text: t("max_length.invalid_value", {size: size_s}))
          return
        end

        spawn bot.answer_callback_query(query.id)
        bot.edit_message_text(
          _chat_id,
          message_id: msg.message_id,
          text: create_text(_group_id, _group_name),
          reply_markup: create_markup(_group_id)
        )
      end
    end

    def create_text(group_id, group_name)
      midcall StrictModeCallback do
        _callback.create_max_length_text(group_id, group_name)
      end
    end

    def create_markup(group_id)
      midcall StrictModeCallback do
        _callback.create_max_length_markup(group_id)
      end
    end
  end
end
