module Policr
  handler PrivateChat do
    match do
      all_pass? [
        from_private_chat?(msg),
        !msg.forward_date, # 非转发消息
        !fetch_state :done { false },
      ]
    end

    handle do
      msg_id = msg.message_id
      chat_id = msg.chat.id

      unless maked_operation? msg.text, chat_id
        if sended_msg = bot.forward_message(
             chat_id: bot.owner_id,
             from_chat_id: msg.chat.id,
             message_id: msg.message_id
           )
          Cache.carving_private_chat_msg "", sended_msg.message_id, {chat_id, msg_id}
        end
      end
    end

    def maked_operation?(text : String | Nil, user_id)
      if text && user_id == bot.owner_id.to_i && text.starts_with?("!")
        begin
          args = text[1..].split(" ")
          case args[0]
          when "group/manage", "gm" # 管理群组列表
            bot.send_message(
              bot.owner_id,
              text: create_manage_text(1),
              reply_markup: create_manage_markup(1)
            )
            true
          when "group/remove", "gr"
            group_id = args[1].to_i64
            Model::Group.cancel_manage group_id
            Cache.delete_group_carving group_id
            true
          when "group/leave", "gl" # 退出群组
            group_id = args[1].to_i64
            bot.leave_chat group_id
            Cache.delete_group_carving group_id
            true
          when "group/trust_admin", "gta"
            group_id = args[1].to_i64
            KVStore.enable_trust_admin group_id
            true
          when "voting/apply_quiz_manage", "vaq" # 申请测验管理
            if sended_msg = bot.send_message bot.owner_id, create_voting_apply_quiz_manage_text
              Cache.carving_voting_apply_quiz_msg bot.owner_id, sended_msg.message_id
              true
            end
          else
            false
          end
        rescue ex : Exception
          bot.send_message bot.owner_id, ex.message || ex.to_s
        end
      end
    end

    def create_voting_apply_quiz_manage_text
      questions = Model::Question.all_voting_apply
      list =
        if questions.size > 0
          questions.map_with_index do |q, i|
            "#{i + 1}. [#{q.title}](https://t.me/#{bot.username}?start=vaqm_#{q.id})"
          end.join("\n")
        else
          t "none"
        end
      t("voting.apply_quiz_manage", {list: list})
    end

    SIZE        = 20
    DATE_FORMAT = "%Y-%m-%d %H:%M:%S"

    def create_manage_text(page_n : Int32)
      offset, limit = paging page_n

      list_sb = String.build do |str|
        groups = load_groups offset, limit
        groups.each do |group|
          chat_id = group.chat_id
          title = group.title
          link = group.link || "[NoneLink]"

          if link == "[NoneLink]" || link.starts_with?("https://t.me/joinchat")
            str << "👥🔒|"
          else
            str << "👥🌐|"
          end
          str << "🆔 `#{chat_id}`|"
          if link.starts_with?("https")
            str << "[#{escape_markdown title}](#{link})"
          else
            str << title
          end
          str << "\n"
        end
        str << "#{t("none")}\n" if str.empty?
        str << "\n页码: #{page_n} 刷新于: #{Time.now.to_s(DATE_FORMAT)}"
      end

      "**受管群组列表**\n\n#{list_sb.to_s}"
    end

    def create_manage_markup(page_n)
      offset, limit = paging page_n
      groups = load_groups offset, (limit + 1)

      make_btn = ->(text : String, n : Int32) {
        Button.new(text: text, callback_data: "Manage:jump:#{n}")
      }
      buttons = [] of Button
      markup = Markup.new

      if page_n > 1 # 存在上一页
        buttons << make_btn.call("上一页", page_n - 1)
      end
      buttons << make_btn.call("刷新", page_n)
      if groups.size > SIZE # 存在下一页
        buttons << make_btn.call("下一页", page_n + 1)
      end
      markup << buttons

      markup
    end

    def paging(n)
      offset = SIZE * (n - 1)
      {offset, SIZE}
    end

    def load_groups(offset, limit)
      Model::Group.load_list(offset, limit)
    end
  end
end
