module Policr
  class EnableExamineCommander < Commander
    def initialize(bot)
      super(bot, "enable_examine")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        text = "已启动审核。包含: 新入群成员的主动验证、Bot 帐号限制、清真移除等功能被开启。"
        if bot.is_admin(msg.chat.id, bot.self_id.to_i32)
          DB.enable_examine(msg.chat.id)
        else
          text = "不给权限还想让人家干活，做梦。"
        end
        bot.reply msg, text
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end
  end
end
