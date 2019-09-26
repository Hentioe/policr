module Policr
  handler BlockContent do
    match do
      chat_id = msg.chat.id

      all_pass? [
        !self_left?,
        from_group_chat?(msg),
        (text = msg.text),
        hit?(chat_id, text), # 命中规则？
        (user = msg.from),
        !has_permission?(chat_id, user.id),
      ]
    end

    handle do
      chat_id = msg.chat.id
      msg_id = msg.message_id

      bot.delete_message(chat_id, msg_id)
    end

    def hit?(chat_id, text)
      Model::BlockContent.load_list(chat_id).each do |rule|
        rule_e = RuleEngine.parse! rule.expression
        return true if rule_e.match? text
      end
    end
  end
end
