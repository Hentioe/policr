module Policr
  class FromCommander < Commander
    def initialize(bot)
      super(bot, "from")
    end

    def handle(msg)
      role = KVStore.trust_admin?(msg.chat.id) ? :admin : :creator
      if (user = msg.from) && bot.has_permission?(msg.chat.id, user.id, role)
        chat_id = msg.chat.id

        sended_msg = bot.send_message(msg.chat.id, text: text(chat_id), reply_to_message_id: msg.message_id, disable_web_page_preview: true, parse_mode: "markdown")
        if sended_msg
          Cache.carving_from_setting_msg chat_id, sended_msg.message_id
        end
      else
        bot.delete_message(msg.chat.id, msg.message_id)
      end
    end

    def text(chat_id)
      from_text =
        if list = KVStore.get_from(chat_id)
          String.build do |str|
            list.each_with_index do |ls, i|
              str << ls.join(" | ")
              str << "\n" if i < (list.size - 1)
            end
          end
        else
          t "from.none"
        end
      t "from.desc", {from_text: from_text}
    end
  end
end
