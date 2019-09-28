module Policr
  handler BlockedContent do
    alias HitResult = Model::BlockRule | Model::GlobalRuleFlag | Nil

    allow_edit

    @result : HitResult?

    match do
      chat_id = msg.chat.id

      all_pass? [
        !self_left?,
        !deleted?,
        examine_enabled?,
        from_group_chat?(msg),
        (text = msg.text),
        (@result = hit?(chat_id, text)), # 命中规则？
        (user = msg.from),
        !has_permission?(chat_id, user.id),
      ]
    end

    handle do
      chat_id = msg.chat.id
      msg_id = msg.message_id

      spawn bot.delete_message(chat_id, msg_id)

      if (result = @result) && (user = msg.from) && (user_id = user.id)
        make_text = ->(action : String) {
          header = t("global_rule_flags.hit_hint.header", {
            mention: FromUser.new(user).mention(user_id.to_s),
          })
          header + t("global_rule_flags.hit_hint.#{action}") + " #GLOBAL_RULES #MESSAGE"
        }

        make_btn = ->(operation : String) {
          Button.new(
            text: t("global_rule_flags.operation.#{operation}"),
            callback_data: "HitRule:#{operation}:#{user_id}"
          )
        }
        make_operate = ->(action : HitAction) {
          case action
          when HitAction::Delete
            [make_btn.call("restrict"), make_btn.call("ban")]
          when HitAction::Restrict
            [make_btn.call("derestrict"), make_btn.call("ban")]
          when HitAction::Ban
            [make_btn.call("unban")]
          else
            Array(TelegramBot::InlineKeyboardButton).new
          end
        }
        markup = Markup.new

        case result
        when Model::GlobalRuleFlag
          action = HitAction.new(result.action)
          markup << make_operate.call(action)

          case action
          when HitAction::Delete
            spawn bot.send_message chat_id, make_text.call("delete"), reply_markup: markup
          when HitAction::Restrict
            spawn {
              bot.restrict chat_id, user_id
              bot.send_message chat_id, make_text.call("restrict"), reply_markup: markup
            }
          when HitAction::Ban
            spawn {
              bot.kick_chat_member chat_id, user_id
              bot.send_message chat_id, make_text.call("ban"), reply_markup: markup
            }
          end
        else
        end
        deleted # 标记删除
      end
    end

    def hit?(chat_id, text) : HitResult
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
