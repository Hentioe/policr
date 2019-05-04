module Policr
  class FromCommander < Commander
    FROM_TIPS =
      <<-TEXT
        您正在设置来源调查，一个具体的例子：

        ```
        -短来源1 -短来源2
        -长长长长长来源3
        -长长长长长来源4
        ```
        如上，每一个来源需要前缀「-」，当多个来源位于同一行时将并列显示，否则独占一行。
        消息不要使用 `Markdown` 格式，在 PC 客户端可能需要 `<Ctrl>+<Enter>` 组合键才能换行。请注意，**只有回复本消息才会被认为是设置来源调查**，并且随着机器人的重启，本消息很可能存在回复有效期。
        TEXT

    def initialize(bot)
      super(bot, "from")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        sended_msg = bot.send_message(msg.chat.id, FROM_TIPS, reply_to_message_id: msg.message_id, parse_mode: "markdown")
        if sended_msg
          Cache.carying_from_setting_msg sended_msg.message_id
        end
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end
  end
end
