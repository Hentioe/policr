module Policr
  class DisableExamineCommander < Commander
    def initialize(bot)
      super(bot, "disable_examine")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        DB.disable_examine(msg.chat.id)
        text = "已禁用审核。包含: 新入群成员的主动验证、Bot 帐号限制、清真移除等功能被关闭。"
        bot.reply msg, text
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end
  end
end
