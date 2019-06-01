module Policr
  class TrustAdminCommander < Commander
    def initialize(bot)
      super(bot, "trust_admin")
    end

    def handle(msg)
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, :creator)
        DB.trust_admin msg.chat.id
        bot.send_message msg.chat.id, t("admin.trust"), reply_to_message_id: msg.message_id, disable_web_page_preview: true, parse_mode: "markdown"
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end
  end
end
