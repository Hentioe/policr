module Policr
  abstract class Commander
    getter name : String
    getter bot : Bot

    def initialize(bot, name)
      @bot = bot
      @name = name
    end

    abstract def handle(msg)

    macro reply_menu
      _chat_id = msg.chat.id
      _group_id = msg.chat.id
      _reply_msg_id = msg.message_id

      role = KVStore.enabled_trust_admin?(_chat_id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(_chat_id, user.id, role)
        if KVStore.enabled_privacy_setting?(_chat_id) && (user = msg.from)
          _chat_id = user.id
          _reply_msg_id = nil
        end

        if %sended_msg = {{yield}}
          Model::PrivateMenu.add(_chat_id, %sended_msg.message_id, msg.chat.id) if _chat_id > 0
        end
      else
        bot.delete_message(_chat_id, msg.message_id)
      end
    end
  end
end
