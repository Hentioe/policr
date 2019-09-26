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
      if (text = msg.text) && (length = @length) && (user = msg.from)
        chat_id = msg.chat.id
        msg_id = msg.message_id
        user_id = user.id

        delete_msg = ->{
          unless has_permission?(chat_id, user_id)
            spawn bot.delete_message chat_id, msg_id

            deleted # 标记删除
          end
        }

        is_delete = false

        if (total = length.total) && (text.size >= total)
          delete_msg.call

          is_delete = true
        end
        if !is_delete && (rows = length.rows) && (text.split("\n").size >= rows)
          delete_msg.call
        end
      end
    end
  end
end
