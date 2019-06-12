module Policr
  class CustomCallback < Callback
    NOT_MODIFIED = "Bad Request: message is not modified: specified new message content and reply markup are exactly the same as a current content and reply markup of the message"

    def initialize(bot)
      super(bot, "Custom")
    end

    def handle(query, msg, report)
      chat_id = msg.chat.id
      from_user_id = query.from.id
      way = report[0]

      # 检测权限
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
      unless (user = msg.from) && bot.has_permission?(msg.chat.id, from_user_id, role)
        bot.answer_callback_query(query.id, text: t("callback.no_permission"), show_alert: true)
        return
      end

      case way
      when "default"
        DB.default chat_id
        text = t "captcha.default"
        bot.edit_message_text chat_id: chat_id, message_id: msg.message_id, text: text, disable_web_page_preview: true, parse_mode: "markdown", reply_markup: create_markup(chat_id)
        bot.answer_callback_query(query.id)
      when "dynamic"
        DB.dynamic chat_id
        text = t "captcha.dynamic"
        bot.edit_message_text chat_id: chat_id, message_id: msg.message_id, text: text, disable_web_page_preview: true, parse_mode: "markdown", reply_markup: create_markup(chat_id)
        bot.answer_callback_query(query.id)
      when "image"
        back_to_default = ->{
          text = t "captcha.default"
          spawn { bot.edit_message_text chat_id: chat_id, message_id: msg.message_id, text: text, disable_web_page_preview: true, parse_mode: "markdown", reply_markup: create_markup(chat_id) }
        }
        # 前提1：数据集数量大于等于3
        if Cache.get_images.size < 3
          back_to_default.call
          bot.answer_callback_query query.id, text: "服务器没有足够的图片数据集，已被禁用", show_alert: true
          DB.disable_image chat_id
          return
        end
        # 前提2：验证时间要大于1分半钟
        torture_sec =
          if sec = DB.get_torture_sec chat_id
            sec
          else
            DEFAULT_TORTURE_SEC
          end
        if torture_sec > 0 && torture_sec < 90
          back_to_default.call
          bot.answer_callback_query query.id, text: "验证时间必须大于1分半钟", show_alert: true
          DB.disable_image chat_id
          return
        end

        DB.enable_image chat_id
        text = t "captcha.image"
        bot.edit_message_text chat_id: chat_id, message_id: msg.message_id, text: text, disable_web_page_preview: true, parse_mode: "markdown", reply_markup: create_markup(chat_id)
        bot.answer_callback_query(query.id)
      when "custom"
        # 缓存此消息
        Cache.carying_custom_msg msg.message_id
        text = t "custom.desc"
        begin
          bot.edit_message_text chat_id: chat_id, message_id: msg.message_id, text: text, disable_web_page_preview: true, parse_mode: "markdown", reply_markup: create_markup(chat_id)
          bot.answer_callback_query(query.id)
        rescue e : TelegramBot::APIException
          _, reason = bot.parse_error e
          bot.answer_callback_query(query.id, text: t("custom.reply_hint")) if reason == NOT_MODIFIED
        end
      end
    end

    def create_markup(chat_id)
      if (commander = bot.commanders[:custom]?) && (commander.is_a?(CustomCommander))
        commander.create_markup(chat_id)
      else
        Markup.new
      end
    end
  end
end
