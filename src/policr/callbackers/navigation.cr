module Policr
  callbacker Navigation do
    def handle(query, msg, data)
      target_group do
        msg_id = msg.message_id
        from_user_id = query.from.id
        name = data[0]

        case name
        when "main"
          def_commander_call NavigationCommander
        when "base_setting"
          def_commander_call SettingsCommander
        when "subfunctions"
          def_commander_call SubfunctionsCommander
        when "custom"
          def_commander_call CustomCommander
        when "torture_time"
          def_commander_call TortureTimeCommander
        when "from"
          def_commander_call FromCommander
        when "welcome"
          def_commander_call WelcomeCommander
        when "clean_mode"
          def_commander_call CleanModeCommander
        when "strict_mode"
          def_commander_call StrictModeCommander
        when "anti_service_msg"
          def_commander_call AntiServiceMsgCommander
        when "template"
          def_commander_call TemplateCommander
        when "language"
          def_commander_call LanguageCommander
        else # 失效键盘
          bot.answer_callback_query(query.id, text: t("invalid_callback"), show_alert: true)
        end
      end
    end

    macro def_commander_call(commander)
      bot.answer_callback_query(query.id)
      midcall {{commander}} do
        _commander.handle msg, from_nav: true
      end
    end
  end
end
