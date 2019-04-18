module Policr
  class DistrustAdminCommander < Commander
    def initialize(bot)
      super(bot, "distrust_admin")
    end

    def handle(msg)
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, :creator)
        DB.distrust_admin msg.chat.id
        bot.reply msg, "已回收其它管理员使用指令调整设置的权力。"
      end
    end
  end
end
