module Policr
  class EnableFromCommander < Commander
    def initialize(bot)
      super(bot, "enable_from")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        if DB.get_chat_from(msg.chat.id)
          DB.enable_chat_from(msg.chat.id)
          text = "已启用来源调查并沿用了之前的设置。如果需要重新设置调查列表，请使用 `/from` 指令。"
          bot.send_message(msg.chat.id, text, reply_to_message_id: msg.message_id, parse_mode: "markdown")
        else
          text = "没有检测到之前的来源设置，请使用 `/from` 指令完成设置。"
          bot.send_message(msg.chat.id, text, reply_to_message_id: msg.message_id, parse_mode: "markdown")
        end
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end
  end
end
