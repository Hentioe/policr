module Policr
  class TortureCallback < Callback
    alias VerifyStatus = Cache::VerifyStatus

    def initialize(bot)
      super(bot, "Torture")
    end

    def handle(query, msg, report)
      chat_id = msg.chat.id
      from_user_id = query.from.id
      target_id, target_username, chooese = report

      chooese_i = chooese.to_i
      target_user_id = target_id.to_i
      message_id = msg.message_id

      if chooese_i == 3
        if target_user_id != from_user_id
          bot.log "Irrelevant User ID '#{from_user_id}' clicked on the verification inline keyboard button"
          bot.answer_callback_query(query.id, text: "(#`Д´)ﾉ 请无关人员不要来搞事", show_alert: true)
          return
        end

        status = Cache.verify?(target_user_id)
        verified_with_receipt(query, chat_id, target_user_id, target_username, message_id) if status == VerifyStatus::Init
        slow_with_receipt(query, chat_id, target_user_id, target_username, message_id) if status == VerifyStatus::Slow
      elsif chooese_i <= 0
        role = DB.trust_admin?(chat_id) ? :admin : :creator

        if bot.has_permission? chat_id, from_user_id, role
          bot.log "The administrator ended the torture by: #{chooese_i}"
          case chooese_i
          when 0
            verified_with_receipt(query, chat_id, target_user_id, target_username, message_id, admin: true)
          when -1
            unverified_with_receipt(chat_id, message_id, target_user_id, target_username, admin: true)
          end
        else
          bot.answer_callback_query(query.id, text: "你怕不是他的同伙吧？不听你的", show_alert: true)
        end
      else
        bot.log "Username '#{target_username}' did not pass verification"
        bot.answer_callback_query(query.id, text: "✖ 未通过验证", show_alert: true)
        unverified_with_receipt(chat_id, message_id, target_user_id, target_username)
      end
    end

    def verified_with_receipt(query, chat_id, target_user_id, target_username, message_id, admin = false)
      Cache.verify_passed(target_user_id)
      bot.log "Username '#{target_username}' passed verification"

      bot.answer_callback_query(query.id, text: "✔ 验证通过", show_alert: true) unless admin
      text = "(*´∀`)~♥ 恭喜您通过了验证，逃过一劫。"
      text = "Σ(*ﾟдﾟﾉ)ﾉ 这家伙走后门进来的，大家快喷他。" if admin

      bot.edit_message_text(chat_id: chat_id, message_id: message_id,
        text: text, reply_markup: nil)

      bot.restrict_chat_member(chat_id, target_user_id, can_send_messages: true)

      from_investigate(chat_id, message_id, target_username, target_user_id) if DB.enabled_from?(chat_id)
    end

    def from_investigate(chat_id, message_id, username, user_id)
      bot.log "From investigation of '#{username}'"
      if from_list = DB.get_chat_from(chat_id)
        index = -1
        btn = ->(text : String) {
          Button.new(text: text, callback_data: "From:#{user_id}:#{username}:#{index += 1}")
        }
        markup = Markup.new
        from_list.each do |btn_text_list|
          markup << btn_text_list.map { |text| btn.call(text) }
        end
        bot.send_message(chat_id, "欢迎 @#{username} 来到这里，告诉大家你从哪里来的吧？小手轻轻一点就行了~", reply_to_message_id: message_id, reply_markup: markup)
      end
    end

    private def slow_with_receipt(query, chat_id, target_user_id, target_username, message_id)
      bot.log "Username '#{target_username}' verification is a bit slower"

      bot.answer_callback_query(query.id, text: "验证通过，但是晚了一点点，再去试试？", show_alert: true)
      bot.edit_message_text(chat_id: chat_id, message_id: message_id,
        text: "(´ﾟдﾟ`) 他通过了验证，但是手慢了那么一点点，再给他一次机会……", reply_markup: nil)
      bot.unban_chat_member(chat_id, target_user_id)
    end

    def unverified_with_receipt(chat_id, message_id, user_id, username, admin = false)
      if (handler = bot.handlers[:join_user]?) && handler.is_a?(JoinUserHandler)
        handler.unverified_with_receipt(chat_id, message_id, user_id, username, admin)
      end
    end
  end
end
