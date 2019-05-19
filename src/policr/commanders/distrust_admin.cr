module Policr
  class DistrustAdminCommander < Commander
    def initialize(bot)
      super(bot, "distrust_admin")
    end

    def handle(msg)
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, :creator)
        DB.distrust_admin msg.chat.id
        bot.reply msg, t "admin.distrust"
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end
  end
end
