module Policr
  callbacker Rule do
    def handle(query, msg, data)
      chat_id = msg.chat.id
      msg_id = msg.message_id

      action, id = data

      case action
      when "question"
        action = data[1]
        id = data[2].to_i32
        case action
        when "delete"
          Model::BlockContent.delete id

          async_response

          bot.delete_message chat_id, msg_id
        when "enable"
          if bc = Model::BlockContent.find(id)
            bc.update_column :is_enabled, true
            updated_text, updated_markup = updated_preview_settings bc

            async_response

            bot.edit_message_text(
              chat_id,
              message_id: msg_id,
              text: updated_text,
              reply_markup: updated_markup
            )
          else
            bot.answer_callback_query(query.id, text: "没有找到这条规则～", show_alert: true)
          end
        when "disable"
          if bc = Model::BlockContent.find(id)
            bc.update_column :is_enabled, false
            updated_text, updated_markup = updated_preview_settings bc

            async_response

            bot.edit_message_text(
              chat_id,
              message_id: msg_id,
              text: updated_text,
              reply_markup: updated_markup
            )
          else
            bot.answer_callback_query(query.id, text: "没有找到这条规则～", show_alert: true)
          end
        else
          invalid_keyboard
        end
      end
    end

    def updated_preview_settings(block_content)
      midcall StartCommander do
        {
          _commander.create_rule_text(block_content),
          _commander.create_rule_markup(block_content),
        }
      end || {nil, nil}
    end
  end
end
