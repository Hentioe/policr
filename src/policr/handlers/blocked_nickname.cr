module Policr
  handler BlockedNickname do
    alias HitResult = Model::BlockRule | Model::GlobalRuleFlag | Nil
    alias MatchedMap = Array(Tuple(TelegramBot::User, HitResult))

    allow_edit

    @matched_map : MatchedMap?

    match do
      all_pass? [
        examine_enabled?,
        (members = msg.new_chat_members),
        (matched_map = matched_map(msg.chat.id, members)),
        matched_map.size > 0,
        (@matched_map = matched_map),
      ]
    end

    handle do
      chat_id = msg.chat.id
      msg_id = msg.message_id

      if matched_map = @matched_map
        matched_map.each do |target_user, result|
          user_id = target_user.id

          # 先处理上报
          if result.is_a?(Model::GlobalRuleFlag) && result.reported
            Cache.carving_report_target_msg chat_id, msg_id, target_user
            midcall ReportCallbacker do
              _callbacker.make_report(
                chat_id: chat_id,
                msg_id: 0, # 无需回复
                target_msg_id: msg_id,
                target_user_id: user_id,
                from_user_id: bot.self_id,
                reason_value: ReportReason::HitGlobalRuleNickname.value
              )
            end
          end

          make_text = ->(action : String) {
            t("global_rule_flags.hit_hint.desc", {
              mention: FromUser.new(target_user).mention(user_id.to_s),
              type:    t("global_rule_flags.hit_hint.type.nickname"),
              result:  t("global_rule_flags.hit_hint.#{action}"),
              tags:    "#GLOBAL_RULES #NICKNAME",
            })
          }

          make_btn = ->(operation : String) {
            Button.new(
              text: t("global_rule_flags.operation.#{operation}"),
              callback_data: "HitRule:#{operation}:#{user_id}"
            )
          }
          make_operate = ->(action : HitAction) {
            case action
            when HitAction::Restrict
              [make_btn.call("pass"), make_btn.call("ban")]
            when HitAction::Ban
              [make_btn.call("unban")]
            else
              Array(TelegramBot::InlineKeyboardButton).new
            end
          }

          # 立即执行可能存在的验证任务
          cancel_verify = ->{
            before = ->{ Cache.verification_left chat_id, user_id }
            after = ->{ Cache.verification_status_clear chat_id, user_id }
            Policr.schedule_immediately("#{chat_id}_#{user_id}", before, after, delete: true)
          }

          markup = Markup.new

          case result
          when Model::GlobalRuleFlag # 命中全局规则
            action = HitAction.new(result.action)
            markup << make_operate.call(action)

            case action
            when HitAction::Restrict
              spawn {
                bot.restrict chat_id, user_id
                cancel_verify.call
                bot.send_message chat_id, make_text.call("restrict"), reply_markup: markup
              }
            when HitAction::Ban
              spawn {
                bot.kick_chat_member chat_id, user_id
                cancel_verify.call
                bot.send_message chat_id, make_text.call("ban"), reply_markup: markup
              }
            end
          else # 命中私有规则
            # 留空
          end
          deleted # 标记删除
        end
      end
    end

    def matched_map(chat_id : Int64,
                    members : Array(TelegramBot::User)) : MatchedMap
      map = MatchedMap.new
      members.each do |member|
        nickname = fullname(member)
        if result = hit?(chat_id, nickname)
          map << {member, result}
        end
      end

      map
    end

    def hit?(chat_id, nickname) : HitResult
      # 全局规则
      if flag = Model::GlobalRuleFlag.enabled?(chat_id)
        Cache.get_global_nickname_rules.each do |block_rule, engine_rule|
          return flag if engine_rule.match? nickname
        end
      end

      # 私有规则
      Model::BlockRule.apply_nickname_list(chat_id).each do |rule|
        ru = RuleEngine.compile! rule.expression
        return rule if ru.match? nickname
      end
    end
  end
end
