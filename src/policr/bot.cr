require "telegram_bot"

module Policr
  class Bot < TelegramBot::Bot
    include TelegramBot::CmdHandler

    def initialize
      super("PolicrBot", Policr.token)

      cmd "hello" do |msg|
        reply msg, "world!"
      end

      # /add 5 7 => 12
      cmd "add" do |msg, params|
        reply msg, "#{params[0].to_i + params[1].to_i}"
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
      puts send_message(chat_id: msg.chat.id, text: "Found a halal").inspect
      kick_r = kick_chat_member(msg.chat.id, member.id)
      puts send_message(chat_id: msg.chat.id, text: "Removing a halal failed~") unless kick_r
      puts send_message(chat_id: msg.chat.id, text: "Successfully removed a halal!") if kick_r
    end
  end
end
