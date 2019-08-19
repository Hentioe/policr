module Policr
  abstract class Callbacker
    getter bot : Bot
    getter name : String

    @current_query : TelegramBot::CallbackQuery?

    def initialize(bot, name)
      @bot = bot
      @name = name
    end

    macro match(name)
      def initialize(bot)
        @bot = bot
        @name = {{name}}.to_s
      end
    end

    def match?(call_name)
      call_name == @name
    end

    abstract def handle(query, msg, report)

    macro target_group
      _group_id = msg.chat.id
      _chat_id = msg.chat.id
      if _chat_id > 0 &&
         (%menu = Model::PrivateMenu.find(_chat_id, msg.message_id)) &&
         KVStore.enabled_privacy_setting?(%menu.group_id)
        _group_id = %menu.group_id
        _group_name = %menu.group_name
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
