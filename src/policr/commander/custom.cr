module Policr
  class CustomCommander < Commander
    REPLY_TIPS =
      <<-TEXT
        开始定制验证问题，一个具体的例子：

        ```
        老鼠不怕哪种动物的声音？
        -嘶嘶 🐍
        -喵喵 🐱
        +汪汪 🐶
        ```
        如上，题目位于第一行，错误答案前缀「-」，正确答案前缀「+」。
        消息不要使用 `Markdown` 格式，在 PC 客户端可能需要 `<Ctrl>+<Enter>` 组合键才能换行。请注意，**只有回复本消息才会被认为是定制验证问题**，并且本消息很可能因为机器人的重启而存在回复有效期。
        TEXT

    def initialize(bot)
      super(bot, "custom")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        sended_msg = bot.send_message(msg.chat.id, REPLY_TIPS, reply_to_message_id: msg.message_id, parse_mode: "markdown")
        if sended_msg
          Cache.carying_custom_msg sended_msg.message_id
        end
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end

    end
  end
end
