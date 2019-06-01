module Policr
  class DistrustAdminCommander < Commander
    def initialize(bot)
      super(bot, "distrust_admin")
    end

    def handle(msg)
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, :creator)
        DB.distrust_admin msg.chat.id
        bot.send_message msg.chat.id, t("admin.distrust"), reply_to_message_id: msg.message_id, disable_web_page_preview: true, parse_mode: "markdown"
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end
  end
end
