require "telegram_bot"
require "json"

module Policr
  SAFE_MSG_SIZE     = 2
  ARABIC_CHARACTERS = /^[\X{0600}-\x{06FF}-\x{0750}-\x{077F}-\x{08A0}-\x{08FF}-\x{FB50}-\x{FDFF}-\x{FE70}-\x{FEFF}-\x{10E60}-\x{10E7F}-\x{1EC70}-\x{1ECBF}-\x{1ED00}-\x{1ED4F}-\x{1EE00}-\x{1EEFF} ]+$/

  class Bot < TelegramBot::Bot
    include TelegramBot::CmdHandler

    def initialize
      super("PolicrBot", Policr.token)

      cmd "ping" do |msg|
        reply msg, "pong"
      end
    end

    def handle(query : TelegramBot::CallbackQuery)
      if message = query.message
        chat_id = message.chat.id
        from_user_id = query.from.id
        member = get_chat_member(chat_id, from_user_id)

        if (user_id = query.data) && (member.status == "creator" || member.status == "admin")
          begin
            unban_r = unban_chat_member(chat_id, user_id.to_i)
            edit_message_text(chat_id: chat_id, message_id: message.message_id,
              text: "(,,・ω・,,) 已经被解封了，快通知他回来。", reply_markup: nil) if unban_r
          rescue e : TelegramBot::APIException
            reason = "原因不明"
            if data = e.data
              reason = data["description"]
            end
            answer_callback_query(query.id, text: "解封失败，#{reason}", show_alert: true)
          end
        else
          answer_callback_query(query.id, text: "(((ﾟДﾟ;))) 你既然不是管理员，那就他的同伙，不听你的", show_alert: true)
        end
      end
    end

    def handle(msg : TelegramBot::Message)
      new_members = msg.new_chat_members
      new_members.each do |member|
        name = "#{member.first_name} #{member.last_name}"
        tick_with_report(msg, member) if name =~ ARABIC_CHARACTERS
      end if new_members
      if (text = msg.text) && (user = msg.from)
        tick_with_report(msg, user) if (text.size > SAFE_MSG_SIZE && text =~ ARABIC_CHARACTERS)
      end
    end

    private def tick_with_report(msg, member)
      sended_msg = reply msg, "d(`･∀･)b 诶发现一名清真，看我干掉它……"
      if sended_msg
        begin
          kick_r = kick_chat_member(msg.chat.id, member.id)
          channed_id = msg.chat.id
          user_id = member.id
          ikb_list = TelegramBot::InlineKeyboardMarkup.new
          ikb_list << TelegramBot::InlineKeyboardButton.new(text: "解除封禁", callback_data: user_id.to_s)
          edit_message_text(chat_id: sended_msg.chat.id, message_id: sended_msg.message_id,
            text: "(ﾉ>ω<)ﾉ 已成功丢出去一只清真，真棒！", reply_markup: ikb_list) if kick_r
        rescue e : TelegramBot::APIException
          edit_message_text(chat_id: sended_msg.chat.id, message_id: sended_msg.message_id,
            text: "╰(〒皿〒)╯ 啥情况，这枚清真移除失败了。") unless kick_r
        end
      end
    end
  end
end
