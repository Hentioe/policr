module Policr
  abstract class Commander
    getter name : String
    getter bot : Bot

    def initialize(bot, name)
      @bot = bot
      @name = name
    end

    def create_markup(group_id) : (Markup | Nil)
      nil
    end

    macro match(name)
      def initialize(bot)
        @bot = bot
        @name = {{name}}.to_s
      end
    end

    abstract def handle(msg)

    BOT_NOT_INIT = "Forbidden: bot can't initiate conversation with a user"
    BOT_BLOCKED  = "Forbidden: bot was blocked by the user"

    CAPTURE_PRIVATE_SETTING_ISSUES = [BOT_NOT_INIT, BOT_BLOCKED]

    macro reply_menu
      _chat_id = msg.chat.id
      _group_id = msg.chat.id
      _reply_msg_id = msg.message_id

      if _chat_id > 0
        bot.send_message _chat_id, text: t("only_group"), reply_to_message_id: _reply_msg_id
        return
      end

      %role = KVStore.enabled_trust_admin?(_group_id) ? :admin : :creator
      if (%user = msg.from) && bot.has_permission?(_chat_id, %user.id, %role)
        if KVStore.enabled_privacy_setting?(_group_id) && (%user = msg.from)
          _chat_id = %user.id
          _group_name = msg.chat.title
          _reply_msg_id = nil
        end

        unless _reply_msg_id
          spawn bot.delete_message _group_id, msg.message_id
          spawn {
            %sended_msg =  bot.send_message _group_id, text: t("private_settings_sended")
            if %sended_msg
              %msg_id = %sended_msg.message_id
              Schedule.after(3.seconds) { bot.delete_message _group_id, %msg_id }
            end
          }
        end

        begin
          if %sended_msg = {{yield}}
            Model::PrivateMenu.add(_chat_id, 
                                   %sended_msg.message_id,
                                   _group_id,
                                   _group_name) if _chat_id > 0
          end
        rescue %ex : TelegramBot::APIException
          _, %reason = bot.parse_error %ex
          %error_msg = 
            if CAPTURE_PRIVATE_SETTING_ISSUES.includes? %reason
              t "private_setting.contact_me"
            else
              bot.log "Private setting failed: #{%reason}"
              t "private_setting.unknown_reason"
            end
          _chat_id = _group_id

          bot.send_message _chat_id, text: %error_msg
          {{yield}}
        end
      else
        bot.delete_message(_chat_id, msg.message_id)
      end
    end

    macro paste_text
      create_text(_group_id, _group_name)
    end

    macro paste_markup
      create_markup(_group_id)
    end

    macro reply(args)
      bot.send_message(_chat_id, reply_to_message_id: _reply_msg_id, {{**args}})
    end
  end
end
