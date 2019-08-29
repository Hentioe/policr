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
            async_response
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
      when "start" # 第一个题目
        verification 0
      when "verification"
        qid = data[1].to_i
        aid = data[2].to_i
        offset = data[3].to_i
        unless Model::Answer.corrected? qid, aid
          note =
            if q = Model::Question.find qid
              q.note
            end
          bot.edit_message_text chat_id, message_id: msg_id, text: t("voting.apply_quiz.failed", {note: note})
          return
        end
        if q = Model::Question.find qid
          text = create_verification_text(q) + "\n您答对了，15 秒后自动进入下一题。请阅读解释：" + (q.note || "")
          bot.edit_message_text chat_id, message_id: msg_id, text: text
          Policr.after 15.seconds do
            verification offset
          end
        else
          bot.answer_callback_query(query.id, text: "没有找到这个问题～", show_alert: true)
        end
      else
        invalid_callback query
      end
    end

    macro verification(offset)
      questions = Model::Question.enabled_voting_apply limit: 1, offset: {{offset}}
      if questions.size > 0
        question = questions[0]
        text = create_verification_text question
        markup = create_verification_markup question, {{offset}}
        bot.edit_message_text chat_id, message_id: msg_id, text: text, reply_markup: markup
      else
        if {{offset}} == Model::Question.enabled_voting_apply.size # 测验结束
          bot.edit_message_text chat_id, message_id: msg_id, text: "恭喜您通过了全部的测验问题，理论上您已具备投票权。只是当前相关功能处于演示阶段，所以您仍然无法进行投票，但很快就会开放并感谢您的参与。\n此演示阶段的意义在于：1. 帮助改善投票申请测验内容 2. 利用正式开放前的空档期对投票进行功能性调整。"
        else
          bot.edit_message_text chat_id, message_id: msg_id, text: "没有找到这个问题～"
        end
      end
    end

    def create_verification_text(question : Model::Question)
      t "voting.apply_quiz.verification", {title: question.title, desc: question.desc}
    end

    def create_verification_markup(question : Model::Question, offset : Int32)
      markup = Markup.new
      question.answers.shuffle.each do |a|
        callback_data = "VotingApplyQuiz:verification:#{question.id}:#{a.id}:#{offset + 1}"
        markup << [Button.new(text: a.name, callback_data: callback_data)]
      end

      markup
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
