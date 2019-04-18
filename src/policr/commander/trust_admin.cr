module Policr
  class TrustAdminCommander < Commander
    def initialize(bot)
      super(bot, "trust_admin")
    end

    def handle(msg)
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, :creator)
        DB.trust_admin msg.chat.id
        bot.reply msg, "已赋予管理员使用指令调整大部分设置的权力。"
      end
    end
  end
end
