module Policr
  class FromCommander < Commander
    def initialize(bot)
      super(bot, "from")
    end

    def handle(msg)
      reply_menu do
        sended_msg = bot.send_message _chat_id, text(_group_id), reply_to_message_id: _reply_msg_id
        if sended_msg
          Cache.carving_from_setting_msg _chat_id, sended_msg.message_id
        end

        sended_msg
      end
    end

    def text(group_id)
      from_text =
        if list = KVStore.get_from(group_id)
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
