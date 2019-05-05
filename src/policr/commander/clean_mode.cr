module Policr
  class EnableCleanModeCommander < Commander
    def initialize(bot)
      super(bot, "clean_mode")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        text = "已启用干净模式，默认级别1：清理通过验证的痕迹。"
        DB.clean_mode(msg.chat.id)
        bot.reply msg, text
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end
  end
end
