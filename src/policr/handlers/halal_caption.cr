module Policr
  handler HalalCaption do
    @caption : String?

    # 待优化：判断文件是否被触发格式限制而删除
    match do
      self_left = read_state :self_left { false }

      all_pass? [
        !self_left,
        from_group_chat?(msg),
        (msg.document || msg.photo),
        (caption = msg.caption),
        is_halal?(caption),
      ]
    end

    handle do
      if member = msg.from
        chat_id = msg.chat.id
        msg_id = msg.message_id

        midcall HalalMessageHandler do
          _handler.kick_halal msg, member
        end
      end
    end

    def is_halal?(caption)
      midcall HalalMessageHandler do
        _handler.is_halal caption
      end
    end
  end
end
