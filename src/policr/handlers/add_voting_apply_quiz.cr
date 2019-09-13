module Policr
  handler AddVotingApplyQuiz do
    allow_edit

    @reply_msg_id : Int32?

    match do
      all_pass? [
        from_private_chat?(msg),
        msg.text,
        (reply_msg = msg.reply_to_message),
        (@reply_msg_id = reply_msg.message_id),
        Cache.voting_apply_quiz_msg?(msg.chat.id, @reply_msg_id), # 回复目标为投票申请测验？
        (user = msg.from),
        user.id == bot.owner_id.to_i32,
      ]
    end

    handle do
      if (text = msg.text) && (reply_msg_id = @reply_msg_id)
        chat_id = msg.chat.id

        begin
          parsed = VotingApplyParser.parse! text
          title = parsed.title || "[NoSet Title]"
          q = Model::Question.create!({
            chat_id: chat_id,
            title:   title,
            desc:    parsed.desc,
            note:    parsed.note,
            use_for: QueUseFor::VotingApplyQuiz.value,
            enabled: true,
          })
          if answers = parsed.answers
            answers.each do |a|
              q.add_answers({:name => a.name, :corrected => a.corrected})
            end
          end
          updated_text = updated_preview_settings
          spawn { bot.edit_message_text(
            chat_id,
            message_id: reply_msg_id,
            text: updated_text,
          ) }

          setting_complete_with_delay_delete msg
        rescue ex : Exception
          bot.send_message chat_id, ex.to_s
        end
      end
    end

    def updated_preview_settings
      midcall PrivateChatHandler do
        _handler.create_voting_apply_quiz_manage_text
      end
    end
  end
end
