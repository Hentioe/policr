module Policr
  abstract class Callback
    getter bot : Bot
    getter name : String

    @current_query : TelegramBot::CallbackQuery?

    def initialize(bot, name)
      @bot = bot
      @name = name
    end

    def match?(call_name)
      call_name == @name
    end

    abstract def handle(query, msg, report)

    macro target_group
      _group_id = msg.chat.id
      _chat_id = msg.chat.id
      if _chat_id > 0 &&
         (%group_id = Model::PrivateMenu.find_group_id(_chat_id, msg.message_id)) &&
         KVStore.enabled_privacy_setting?(%group_id)
        _group_id = %group_id
      end

      %role = KVStore.enabled_trust_admin?(_group_id) ? :admin : :creator

      unless bot.has_permission?(_group_id, query.from.id, %role)
        bot.answer_callback_query(query.id, text: t("callback.no_permission"), show_alert: true)
        return
      end

      {{yield}}
    end
  end
end
