require "telegram_bot"
require "json"

module Policr
  class Bot < TelegramBot::Bot
    include TelegramBot::CmdHandler

    def initialize
      super("PolicrBot", Policr.token)

      cmd "hello" do |msg|
        reply msg, "world!"
      end
    end

    ARABIC_CHARACTERS = /^[\x{0600}-\x{06ff}-\x{0750}-\x{077f}-\x{08A0}-\x{08ff}-\x{fb50}-\x{fdff}-\x{fe70}-\x{feff} ]+$/

    def handle(msg : TelegramBot::Message)
      new_members = msg.new_chat_members
      new_members.each do |member|
        name = "#{member.first_name} #{member.last_name}"
        tick_with_report(msg, member) if name =~ ARABIC_CHARACTERS
      end if new_members
      if (text = msg.text) && (user = msg.from)
        tick_with_report(msg, user) if text =~ ARABIC_CHARACTERS
      end
    end

    private def tick_with_report(msg, member)
      sended_msg = reply msg, "d(`･∀･)b 诶发现一名清真，看我干掉它……"
      if sended_msg
        begin
          kick_r = kick_chat_member(msg.chat.id, member.id)
          edit_message_text(chat_id: sended_msg.chat.id, message_id: sended_msg.message_id,
            text: "(ﾉ>ω<)ﾉ 已成功丢出去一只清真，真棒！") if kick_r
        rescue e : TelegramBot::APIException
          edit_message_text(chat_id: sended_msg.chat.id, message_id: sended_msg.message_id,
            text: "╰(〒皿〒)╯ 啥情况，这枚清真移除失败了。") unless kick_r
        end
      end
    end
  end
end
