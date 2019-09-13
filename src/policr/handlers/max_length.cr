module Policr
  handler MaxLength do
    @length : Model::MaxLength?

    match do
      self_left = read_state :self_left { false }

      all_pass? [
        !self_left,
        from_group_chat?(msg),
        (@length = Model::MaxLength.find(msg.chat.id)), # 启用了相关设置？
      ]
    end

    handle do
      if (text = msg.text) && (length = @length)
        chat_id = msg.chat.id
        msg_id = msg.message_id

        delete_msg = ->{
          bot.delete_message chat_id, msg_id
        }

        deleted = false
        if (total = length.total) && (text.size >= total)
          deleted = true
          spawn delete_msg.call
        end
        if !deleted && (rows = length.rows) && (text.split("\n").size >= rows)
          delete_msg.call
        end
      end
    end
  end
end
