module Policr
  handler AddGlobalRule do
    allow_edit

    @reply_msg_id : Int32?

    match do
      all_pass? [
        from_private_chat?(msg),
        msg.text,
        (reply_msg = msg.reply_to_message),
        (@reply_msg_id = reply_msg.message_id),
        Cache.global_rules_msg?(msg.chat.id, @reply_msg_id), # 回复目标为全局规则管理？
        (user = msg.from),
        user.id == bot.owner_id.to_i32,
      ]
    end

    handle do
      if (text = msg.text) && (reply_msg_id = @reply_msg_id)
        chat_id = msg.chat.id

        begin
          parsed = BlockContentParser.parse! text

          Model::BlockRule.add!(bot.self_id.to_i64, parsed.rule.not_nil!, parsed.alias_s.not_nil!)

          updated_text, updated_markup = update_preview_settings
          spawn { bot.edit_message_text(
            chat_id,
            message_id: reply_msg_id,
            text: updated_text,
            reply_markup: updated_markup
          ) }

          # 重新编译全局规则
          Cache.recompile_global_rules bot

          setting_complete_with_delay_delete msg
        rescue e : Exception
          bot.send_message chat_id, e.to_s
        end
      end
    end

    def update_preview_settings
      midcall PrivateChatHandler do
        {
          _handler.create_global_rules_text,
          _handler.create_global_rules_markup,
        }
      end || {nil, nil}
    end
  end
end
