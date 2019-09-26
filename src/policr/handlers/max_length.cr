module Policr
  handler MaxLength do
    @length : Model::MaxLength?

    match do
      all_pass? [
        !self_left?,
        !deleted?,
        examine_enabled?,
        from_group_chat?(msg),
        (@length = Model::MaxLength.find(msg.chat.id)), # 启用了相关设置？
      ]
    end

    handle do
      if (text = msg.text) && (length = @length)
        chat_id = msg.chat.id
        msg_id = msg.message_id

        delete_msg = ->{
          spawn bot.delete_message chat_id, msg_id

          deleted # 标记删除
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
