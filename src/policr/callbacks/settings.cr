module Policr
  class SettingsCallback < Callback
    NOT_MODIFIED = "Bad Request: message is not modified: specified new message content and reply markup are exactly the same as a current content and reply markup of the message"

    def initialize(bot)
      super(bot, "Settings")
    end

    def handle(query, msg, data)
      chat_id = msg.chat.id
      from_user_id = query.from.id
      name = data[0]

      # 检测权限
      role = KVStore.enabled_trust_admin?(msg.chat.id) ? :admin : :creator
      unless (user = msg.from) && bot.has_permission?(msg.chat.id, from_user_id, role)
        bot.answer_callback_query(query.id, text: t("callback.no_permission"), show_alert: true)
        return
      end

      case name
      when "enable_examine"
        selected = KVStore.enabled_examine?(chat_id)
        selected ? KVStore.disable_examine(chat_id) : KVStore.enable_examine(chat_id)
        text = t "settings.desc", {last_change: def_change}
        spawn bot.answer_callback_query(query.id)
        bot.edit_message_text(
          chat_id,
          message_id: msg.message_id,
          text: text,
          reply_markup: create_markup(chat_id)
        )
      when "trust_admin"
        selected = KVStore.enabled_trust_admin?(chat_id)
        selected ? KVStore.disable_trust_admin(chat_id) : KVStore.enable_trust_admin(chat_id)
        text = t "settings.desc", {last_change: def_change}
        spawn bot.answer_callback_query(query.id)
        bot.edit_message_text(
          chat_id,
          message_id: msg.message_id,
          text: text,
          reply_markup: create_markup(chat_id)
        )
      when "record_mode"
        selected = KVStore.enabled_record_mode?(chat_id)
        selected ? KVStore.disable_record_mode(chat_id) : KVStore.enable_record_mode(chat_id)
        text = t "settings.desc", {last_change: def_change}
        spawn bot.answer_callback_query(query.id)
        bot.edit_message_text(
          chat_id,
          message_id: msg.message_id,
          text: text,
          reply_markup: create_markup(chat_id)
        )
      when "enable_from"
        unless KVStore.get_from(chat_id)
          bot.answer_callback_query(query.id, text: t("settings.not_from"), show_alert: true)
          return
        end
        selected = KVStore.enabled_from?(chat_id)
        selected ? KVStore.disable_from(chat_id) : KVStore.enable_from(chat_id)
        text = t "settings.desc", {last_change: def_change}
        spawn bot.answer_callback_query(query.id)
        bot.edit_message_text(
          chat_id,
          message_id: msg.message_id,
          text: text,
          reply_markup: create_markup(chat_id)
        )
      when "welcome"
        unless KVStore.get_welcome(chat_id)
          bot.answer_callback_query(query.id, text: t("settings.not_welcome"), show_alert: true)
          return
        end
        selected = KVStore.enabled_welcome?(chat_id)
        selected ? KVStore.disable_welcome(chat_id) : KVStore.enable_welcome(chat_id)
        text = t "settings.desc", {last_change: def_change}
        spawn bot.answer_callback_query(query.id)
        bot.edit_message_text(
          chat_id,
          message_id: msg.message_id,
          text: text,
          reply_markup: create_markup(chat_id)
        )
      when "fault_tolerance"
        unless KVStore.enabled_dynamic_captcha?(chat_id) ||
               KVStore.enabled_image_captcha?(chat_id) ||
               KVStore.enabled_chessboard_captcha?(chat_id)
          bot.answer_callback_query(query.id, text: t("settings.fault_tolerance_not_supported"), show_alert: true)
          return
        end
        selected = KVStore.enabled_fault_tolerance?(chat_id)
        selected ? KVStore.disable_fault_tolerance(chat_id) : KVStore.enable_fault_tolerance(chat_id)
        text = t "settings.desc", {last_change: def_change}
        spawn bot.answer_callback_query(query.id)
        bot.edit_message_text(
          chat_id,
          message_id: msg.message_id,
          text: text,
          reply_markup: create_markup(chat_id)
        )
      end
    end

    macro def_change
      (selected ? t("settings.unselected") : t("settings.selected")) + t("settings.#{name}")
    end

    def create_markup(chat_id)
      midcall SettingsCommander do
        commander.create_markup(chat_id)
      end
    end
  end
end
