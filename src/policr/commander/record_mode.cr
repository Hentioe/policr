module Policr
  class EnableRecordModeCommander < Commander
    def initialize(bot)
      super(bot, "record_mode")
    end

    def handle(msg)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        text = "已启用记录模式，将保留所有中间步骤消息。"
        DB.record_mode(msg.chat.id)
        bot.reply msg, text
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end
  end
end
