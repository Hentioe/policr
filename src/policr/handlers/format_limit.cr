module Policr
  handler FormatLimit do
    def match(msg)
      role = KVStore.enabled_trust_admin?(msg.chat.id) ? :admin : :creator

      all_pass? [
        msg.document,
        (user = msg.from),
        !bot.has_permission?(msg.chat.id, user.id, role),
      ]
    end

    def handle(msg)
      if document = msg.document
        chat_id = msg.chat.id
        msg_id = msg.message_id

        if file_name = document.file_name
          extname = File.extname file_name
          extname = extname.gsub(/^\./, "")
          bot.delete_message(chat_id, msg_id) if Model::FormatLimit.includes?(chat_id, extname)
        end
      end
    end
  end
end
