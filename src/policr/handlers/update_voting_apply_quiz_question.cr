module Policr
  handler UpdateVotingApplyQuizQuestion do
    allow_edit

    @reply_msg_id : Int32?
    @qid : Int32?

    match do
      all_pass? [
        msg.text,
        from_private_chat?(msg),
        (reply_msg = msg.reply_to_message),
        (@reply_msg_id = reply_msg.message_id),
        (@qid = Cache.voting_apply_quiz_question_msg?(msg.chat.id, @reply_msg_id)), # 回复目标为投票申请测验问题？
        (user = msg.from),
        user.id == bot.owner_id.to_i32,
      ]
    end

    handle do
      if (text = msg.text) &&
         (reply_msg_id = @reply_msg_id) &&
         (qid = @qid) &&
         (question = Model::Question.find(qid))
        chat_id = msg.chat.id

        begin
          parsed = VotingApplyParser.parse! text
          title = parsed.title || "[NoSet Title]"
          # 清空原有答案
          question.answers.each_with_index do |a, i|
            Model::Answer.delete a.id
          end

          question.answers.clear

          question.update_columns({
            :title => title,
            :desc  => parsed.desc,
            :note  => parsed.note,
          })
          if answers = parsed.answers
            answers.each do |a|
              question.add_answers({:name => a.name, :corrected => a.corrected})
            end
          end
          updated_text, updated_markup = updated_preview_settings question
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

    def updated_preview_settings(question)
      midcall StartCommander do
        {
          _commander.create_voting_apply_quiz_question_text(question),
          _commander.create_voting_apply_quiz_question_markup(question),
        }
      end || {nil, nil}
    end
  end
end
