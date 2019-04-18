module Policr
  class StartCommander < Commander
    def initialize(bot)
      super(bot, "start")
    end

    def handle(msg)
      text =
        "欢迎使用 ε٩(๑> ₃ <)۶з 我是强大的审核机器人 PolicrBot。我的主要功能不会主动开启，需要通过指令手动启用或设置。推荐在 Github 上查看我的指令用法 ~"
      bot.send_message(msg.chat.id, text, reply_to_message_id: msg.message_id, parse_mode: "markdown")
    end
  end
end
