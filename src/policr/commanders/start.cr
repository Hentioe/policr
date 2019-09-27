module Policr
  commander Start do
    def handle(msg, from_nav)
      chat_id = msg.chat.id
      user_id =
        if user = msg.from
          user.id
        else
          0
        end

      payload =
        if (text = msg.text) && (args = text.split(" ")) && args.size > 1
          args[1]
        end
      if payload
        spawn bot.delete_message chat_id, msg.message_id
        forward_to payload, chat_id, user_id
      else
        text = t "start"
        bot.send_message chat_id, text
      end
    end

    def forward_to(payload, chat_id, user_id)
      if md = /^([^_]+)_(.+)$/.match payload
        key = md[1]
        data = md[2]
        case key
        when "vaqm"
          id = data.to_i
          if q = Model::Question.find(id)
            text = create_voting_apply_quiz_question_text q
            markup = create_voting_apply_quiz_question_markup q
            if sended_msg = bot.send_message chat_id, text, reply_markup: markup
              Cache.carving_voting_apply_quiz_question_msg chat_id, sended_msg.message_id, id
            end
          end
        when "rule"
          id = data.to_i
          if bc = Model::BlockRule.find(id)
            group_id = bc.chat_id
            role = Model::Toggle.trusted_admin?(group_id) ? :admin : :creator

            if bot.has_permission?(bc.chat_id, user_id, role)
              text = create_block_rule_text bc
              markup = create_block_rule_markup bc
              if sended_msg = bot.send_message chat_id, text, reply_markup: markup
                Cache.carving_rule_msg chat_id, sended_msg.message_id, id
              end
            else
              bot.send_message chat_id, "您没有权限查看此内容。"
            end
          else
            bot.send_message chat_id, "Not Found"
          end
        when "welcome"
          id = data.to_i
          if (welcome = Model::Welcome.find(id)) &&
             (parsed = WelcomeContentParser.parse welcome.content)
            disable_link_preview = Model::Welcome.link_preview_disabled?(chat_id)
            text =
              parsed.content || "Warning: welcome content format is incorrect"

            markup = Markup.new
            if parsed.buttons.size > 0
              parsed.buttons.each do |button|
                markup << [Button.new(text: button.text, url: button.link)]
              end
            end
            bot.send_message(
              chat_id,
              text: text,
              reply_markup: markup,
              disable_web_page_preview: disable_link_preview
            )
          else
            bot.send_message chat_id, "Not Found"
          end
        end
      end
    end

    def create_voting_apply_quiz_question_text(question : Model::Question)
      answers_s = question.answers.map do |a|
        make_icon = ->{
          a.corrected ? "√" : "×"
        }
        "#{make_icon.call} #{a.name}"
      end.join("\n")
      t "voting.apply_quiz_question", {
        title:   question.title,
        desc:    question.desc,
        note:    question.note,
        answers: answers_s,
      }
    end

    def create_voting_apply_quiz_question_markup(question : Model::Question)
      make_btn = ->(action : String) {
        callback_data = "VotingApplyQuiz:question:#{action}:#{question.id}"
        Button.new(text: t("voting.apply_quiz.question.#{action}"), callback_data: callback_data)
      }
      markup = Markup.new
      buttons = Array(Button).new
      buttons << make_btn.call("disable") if question.enabled
      buttons << make_btn.call("enable") unless question.enabled
      buttons << make_btn.call("delete")
      markup << buttons

      markup
    end

    def create_block_rule_text(bc : Model::BlockRule)
      rule_template = "-a #{bc.alias_s}\n#{bc.expression}"
      t "blocked_content.rule.manage", {rule_name: bc.alias_s, rule_template: rule_template}
    end

    def create_block_rule_markup(bc : Model::BlockRule)
      make_btn = ->(action : String) {
        callback_data = "BlockRule:#{action}:#{bc.id}"
        Button.new(text: t("blocked_content.rule.#{action}"), callback_data: callback_data)
      }
      markup = Markup.new
      buttons = Array(Button).new
      buttons << make_btn.call("disable") if bc.enabled
      buttons << make_btn.call("enable") unless bc.enabled
      buttons << make_btn.call("delete")
      markup << buttons

      markup
    end
  end
end
