module Policr
  class BotJoinCallback < Callback
    def initialize(bot)
      super(bot, "BotJoin")
    end

    def handle(query, msg, report)
      chat_id = msg.chat.id
      from_user_id = query.from.id
      target_id, _, chooese = report

      chooese_id = chooese.to_i
      bot_id = target_id.to_i
      message_id = msg.message_id

      role = DB.trust_admin?(chat_id) ? :admin : :creator

      unless bot.has_permission? chat_id, from_user_id, role
        bot.log "User ID '#{from_user_id}' without permission click to unrestrict button"
        bot.answer_callback_query(query.id, text: "你怕不是它的同伙吧？不听你的", show_alert: true)
        return
      end

      text = "已解除限制，希望是个有用的机器人。"
      case chooese_id
      when 0
        bot.restrict_chat_member(chat_id, bot_id, can_send_messages: true, can_send_media_messages: true, can_send_other_messages: true, can_add_web_page_previews: true)
      when -1
        bot.kick_chat_member(chat_id, bot_id)
        text = "已经被移除啦~安全危机解除！"
      else
        text = "此消息的内联键盘功能已经过时了，没有进行任何操作~"
      end
      bot.edit_message_text(chat_id: chat_id, message_id: message_id,
        text: text, reply_markup: nil)
    end
  end
end
