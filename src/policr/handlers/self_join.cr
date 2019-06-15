module Policr
  class SelfJoinHandler < Handler
    alias VerifyStatus = Cache::VerifyStatus

    def match(msg)
      all_pass? [
        msg.new_chat_members,
      ]
    end

    def handle(msg)
      chat_id = msg.chat.id

      if members = msg.new_chat_members
        members.select { |m| m.is_bot }.select { |m| m.id == bot.self_id }.each do |member| # 自己被拉入群组？
          markup = Markup.new
          make_btn = ->(text : String, item : String) {
            Button.new(text: text, callback_data: "SelfJoin:#{item}")
          }
          markup << [make_btn.call t("add_to_group.leave"), "leave"]
          if (user = msg.from)
            user_data = {name: bot.display_name(user), user_id: user.id}
            is_admin = bot.is_admin?(chat_id, user.id)
            text =
              if is_admin
                t "add_to_group.from_admin", user_data
              else
                t "add_to_group.from_user", user_data
              end
            sended_msg = bot.send_message chat_id, text, reply_markup: markup, parse_mode: "markdown", disable_web_page_preview: true
            if tmp_msg = sended_msg
              message_id = tmp_msg.message_id
              # 自动离开定时任务
              Schedule.after((60*30).seconds) {
                unless bot.is_admin?(chat_id, bot.self_id.to_i32) # 仍然没有管理员权限
                  bot.delete_message chat_id, message_id
                  bot.leave_chat chat_id
                end
              } unless is_admin
            end
          end
        end
      end
    end
  end
end
