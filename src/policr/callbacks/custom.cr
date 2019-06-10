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
        text = "已恢复默认验证。注意，默认验证并不是永久固定的，它会随着机器人的不断更新而改进。"
        bot.edit_message_text chat_id: chat_id, message_id: msg.message_id, text: text, disable_web_page_preview: true, parse_mode: "markdown", reply_markup: create_markup(chat_id)
        bot.answer_callback_query(query.id)
      when "dynamic"
        DB.dynamic chat_id
        text = "已启用动态验证。与默认或自定义验证不同，动态验证的问题和答案不是固定的，通常会是求解随机生成的计算公式或者与之类似的问题，它们不会让人感到困难。\n动态验证的方式并不是永久固定的，它会随着机器人的不断更新而改进。"
        bot.edit_message_text chat_id: chat_id, message_id: msg.message_id, text: text, disable_web_page_preview: true, parse_mode: "markdown", reply_markup: create_markup(chat_id)
        bot.answer_callback_query(query.id)
      when "custom"
        # 缓存此消息
        Cache.carying_custom_msg msg.message_id
        text = t("custom.custom")
        begin
          bot.edit_message_text chat_id: chat_id, message_id: msg.message_id, text: text, disable_web_page_preview: true, parse_mode: "markdown", reply_markup: create_markup(chat_id)
        bot.answer_callback_query(query.id)
        rescue e : TelegramBot::APIException
          _, reason = bot.parse_error e
          bot.answer_callback_query(query.id, text: "可以回复本消息啦") if reason == NOT_MODIFIED
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
