module Policr
  handler UpdateRule do
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
         (id = @id) &&
         (rule = Model::BlockContent.find(id))
        chat_id = msg.chat.id

        begin
          rule.update_columns({
            :alias_s    => "暂定别名",
            :expression => text,
          })

          updated_text, updated_markup = updated_preview_settings rule
          spawn { bot.edit_message_text(
            chat_id,
            message_id: reply_msg_id,
            text: updated_text,
            reply_markup: updated_markup
          ) }

          setting_complete_with_delay_delete msg
        rescue ex : Exception
          bot.send_message chat_id, ex.to_s
        end
      end
    end

    def updated_preview_settings(rule)
      midcall StartCommander do
        {
          _commander.create_rule_text(rule),
          _commander.create_rule_markup(rule),
        }
      end || {nil, nil}
    end
  end
end
