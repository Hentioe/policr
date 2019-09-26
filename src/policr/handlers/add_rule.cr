module Policr
  MAX_RULE_LENGTH = 180

  handler AddRule do
    allow_edit
    target :fields

    match do
      target :group do
        all_pass? [
          (@reply_msg_id = _reply_msg_id),
          Cache.blocked_content_msg?(msg.chat.id, @reply_msg_id), # 回复目标为添加屏蔽内容？
          msg.text,
          (user = msg.from),
          has_permission?(_group_id, user.id),
        ]
      end
    end

    handle do
      retrieve [(text = msg.text)] do
        chat_id = msg.chat.id

        if Model::BlockContent.counts(_group_id) >= 5
          bot.send_message chat_id, "您的规则数量达到上限，建议整理并合并旧有规则。"
        elsif text.size > MAX_RULE_LENGTH
          bot.send_message chat_id, t("content_blocked.too_long", {size: MAX_RULE_LENGTH})
        else
          begin
            parsed = BlockContentParser.parse! text

            Model::BlockContent.add!(_group_id, parsed.rule.not_nil!, parsed.alias_s.not_nil!)

            update_text, update_markup = update_preview_settings(_group_id, _group_name)
            spawn { bot.edit_message_text(
              chat_id,
              message_id: _reply_msg_id,
              text: update_text,
              reply_markup: update_markup
            ) }

            setting_complete_with_delay_delete msg
          rescue e : Exception
            bot.send_message chat_id, e.to_s
          end
        end
      end
    end

    def update_preview_settings(group_id, group_name)
      midcall StrictModeCallbacker do
        {
          _callbacker.create_content_blocked_text(group_id, group_name),
          _callbacker.create_content_blocked_markup(group_id),
        }
      end || {nil, nil}
    end
  end
end
