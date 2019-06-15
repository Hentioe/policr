module Policr
  class SelfJoinCallback < Callback
    def initialize(bot)
      super(bot, "SelfJoin")
    end

    def handle(query, msg, item)
      chat_id = msg.chat.id
      from_user_id = query.from.id
      message_id = msg.message_id
      action = item[0]

      unless bot.is_admin? chat_id, from_user_id
        bot.log "User '#{from_user_id}' without permission click button"
        bot.answer_callback_query(query.id, text: t("add_to_group.no_permission"), show_alert: true)
        return
      end

      case action
      when "leave"
        spawn { bot.answer_callback_query(query.id) }
        bot.delete_message chat_id, message_id
        bot.leave_chat chat_id
      end
    end
  end
end
