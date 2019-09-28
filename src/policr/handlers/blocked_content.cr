module Policr
  handler BlockedContent do
    allow_edit

    match do
      chat_id = msg.chat.id

      all_pass? [
        !self_left?,
        !deleted?,
        examine_enabled?,
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

      spawn bot.delete_message(chat_id, msg_id)

      deleted # 标记删除
    end

    def hit?(chat_id, text) : Model::BlockRule | Model::GlobalRuleFlag | Nil
      # 全局规则
      if flag = Model::GlobalRuleFlag.enabled?(chat_id)
        Cache.get_global_message_rules.each do |block_rule, engine_rule|
          return flag if engine_rule.match? text
        end
      end

      # 私有规则
      Model::BlockRule.apply_message_list(chat_id).each do |rule|
        ru = RuleEngine.compile! rule.expression
        return rule if ru.match? text
      end
    end
  end
end
