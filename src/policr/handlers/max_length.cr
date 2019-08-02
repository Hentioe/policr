module Policr
  handler MaxLength do
    @length : Model::MaxLength?

    def match(msg)
      all_pass? [
        (@length = Model::MaxLength.find(msg.chat.id)), # 启用了相关设置？
      ]
    end

    def handle(msg)
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
