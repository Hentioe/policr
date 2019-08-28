module Policr
  callbacker VotingApplyQuiz do
    def handle(query, msg, data)
      chat_id = msg.chat.id
      msg_id = msg.message_id

      category = data[0]

      unless chat_id == bot.owner_id.to_i32
        bot.answer_callback_query(query.id, text: t("callback.no_permission"), show_alert: true)
        return
      end

      case category
      when "question"
        action = data[1]
        id = data[2].to_i32
        case action
        when "delete"
          Model::Question.delete id
          bot.answer_callback_query(query.id)
          bot.delete_message chat_id, msg.message_id
        when "enable"
          if q = Model::Question.find(id)
            q.update_column :enabled, true
            updated_text, updated_markup = updated_preview_settings q
            bot.edit_message_text(
              chat_id,
              message_id: msg_id,
              text: updated_text,
              reply_markup: updated_markup
            )
          else
            bot.answer_callback_query(query.id, text: "没有找到这个问题～", show_alert: true)
          end
        when "disable"
          if q = Model::Question.find(id)
            q.update_column :enabled, false
            updated_text, updated_markup = updated_preview_settings q
            bot.edit_message_text(
              chat_id,
              message_id: msg_id,
              text: updated_text,
              reply_markup: updated_markup
            )
          else
            bot.answer_callback_query(query.id, text: "没有找到这个问题～", show_alert: true)
          end
        else
          invalid_callback query
        end
      else
        invalid_callback query
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
