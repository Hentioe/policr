module Policr
  handler PrivateChat do
    match do
      all_pass? [
        from_private_chat?(msg),
        !msg.forward_date, # 非转发消息
        !read_state :done { false },
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
          when "manage" # 管理群组列表
            list_sb = String.build do |str|
              Cache.serving_groups.each do |chat_id, info|
                link, title = info
                if link.starts_with? "t.me"
                  str << "👥🌐|"
                else
                  str << "👥🔒|"
                end
                str << "🆔 `#{chat_id}`|"
                if link.starts_with?("t.me") || link.starts_with?("https")
                  str << "[#{title}](#{link})"
                else
                  str << escape_markdown(title)
                end
                str << "\n"
              end
            end
            text =
              if list_sb.to_s.empty?
                t "none"
              else
                list_sb.to_s
              end
            bot.send_message bot.owner_id, text: text
          when "leave"
            group_id = args[1].to_i64
            bot.leave_chat group_id
            Cache.delete_group group_id
          else
            nil
          end
        rescue ex : Exception
          bot.send_message bot.owner_id, ex.message || ex.to_s
        end
      end
    end
  end
end
