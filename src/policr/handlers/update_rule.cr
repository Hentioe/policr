module Policr
  handler UpdateRule do
    alias BlockRule = Model::BlockRule

    allow_edit

    @reply_msg_id : Int32?
    @id : Int32?

    match do
      all_pass? [
        from_private_chat?(msg),
        (reply_msg = msg.reply_to_message),
        (@reply_msg_id = reply_msg.message_id),
        (@id = Cache.rule_msg?(msg.chat.id, @reply_msg_id)), # 回复目标为修改规则？
        msg.text,
      ]
    end

    handle do
      if (text = msg.text) &&
         (reply_msg_id = @reply_msg_id) &&
         (id = @id)
        chat_id = msg.chat.id
        user_id =
          if user = msg.from
            user.id
          else
            0
          end

        rule = BlockRule.find id

        unless rule
          bot.send_message chat_id, t "blocked_content.rule.not_found"
          return fetch_state :done { true }
        end

        rule = rule.not_nil!
        is_global_rule = false

        has_permission =
          if rule.chat_id == bot.self_id # 全局规则
            is_global_rule = true
            user_id == bot.owner_id.to_i # 是否为管理员操作
          else                           # 私有规则
            role = Model::Toggle.trusted_admin?(rule.chat_id) ? :admin : :creator
            bot.has_permission?(rule.chat_id, user_id, role)
          end
        unless has_permission
          bot.send_message(chat_id, "您没有权限操作此内容～")
        else
          if text.size > MAX_RULE_LENGTH
            bot.send_message chat_id, t("blocked_content.too_long", {size: MAX_RULE_LENGTH})
          else
            begin
              parsed = BlockContentParser.parse! text

              rule = Model::BlockRule.update!(id, parsed.rule.not_nil!, parsed.alias_s.not_nil!)

              updated_text, updated_markup = updated_preview_settings rule
              spawn { bot.edit_message_text(
                chat_id,
                message_id: reply_msg_id,
                text: updated_text,
                reply_markup: updated_markup
              ) }

              # 如果是全局规则更新则重新编译
              Cache.recompile_global_rules bot if is_global_rule

              setting_complete_with_delay_delete msg
            rescue ex : Exception
              bot.send_message chat_id, ex.to_s
            end
          end
        end
      end
    end

    def updated_preview_settings(rule)
      midcall StartCommander do
        {
          _commander.create_block_rule_text(rule),
          _commander.create_block_rule_markup(rule),
        }
      end || {nil, nil}
    end
  end
end
