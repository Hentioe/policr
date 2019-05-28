module Policr
  class ReportCommander < Commander
    def initialize(bot)
      super(bot, "report")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        # 进行封禁并转发投票
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end
  end
end
