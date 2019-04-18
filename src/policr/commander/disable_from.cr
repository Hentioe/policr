module Policr
  class DisableFromCommander < Commander
    def initialize(bot)
      super(bot, "disable_from")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        DB.disable_chat_from(msg.chat.id)

        text = "已禁用来源调查功能，启用请使用 `/from` 指令完成设置。"
        text = "已禁用来源调查功能，相关设置将会在下次启用时继续沿用。" if DB.get_chat_from(msg.chat.id)
        bot.send_message(msg.chat.id, text, reply_to_message_id: msg.message_id, parse_mode: "markdown")
      end
    end
  end
end
