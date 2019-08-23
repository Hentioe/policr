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
            bot.send_message(
              bot.owner_id,
              text: create_manage_text(1),
              reply_markup: create_manage_markup(1)
            )
          when "leave"
            group_id = args[1].to_i64
            bot.leave_chat group_id
            Cache.delete_group(group_id)
          else
            nil
          end
        rescue ex : Exception
          bot.send_message bot.owner_id, ex.message || ex.to_s
        end
      end
    end

    SIZE        = 20
    DATE_FORMAT = "%Y-%m-%d %H:%M:%S"

    def create_manage_text(page_n : Int32)
      offset, limit = gen_ranging page_n

      list_sb = String.build do |str|
        groups = loading_groups offset, limit
        groups.each do |chat_id, info|
          link, title, _ = info
          if link.starts_with? "t.me"
            str << "👥🌐|"
          else
            str << "👥🔒|"
          end
          str << "🆔 `#{chat_id}`|"
          if link.starts_with?("t.me") || link.starts_with?("https")
            str << "[#{title}](#{link})"
          else
            str << title
          end
          str << "\n"
        end
        str << "\n页码: #{page_n} 刷新于: #{Time.now.to_s(DATE_FORMAT)}"
      end

      if list_sb.to_s.empty?
        t "none"
      else
        list_sb.to_s
      end
    end

    def create_manage_markup(page_n)
      offset, limit = gen_ranging page_n
      groups = loading_groups offset, (limit + 1)

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

    def gen_ranging(n)
      offset = SIZE * (n - 1)
      limit = n * SIZE
      {offset, limit}
    end

    def loading_groups(offset, limit)
      i = 0
      Cache.serving_groups.to_a.sort_by do |k, v|
        _, _, no = v
        no
      end.select do
        i += 1
        i > offset && i <= limit
      end
    end
  end
end
