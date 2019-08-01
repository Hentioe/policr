module Policr
  class AntiServiceMsgCommander < Commander
    alias DeleteTarget = AntiMessageDeleteTarget

    def initialize(bot)
      super(bot, "anti_service_msg")
    end

    def handle(msg)
      reply_menu do
        bot.send_message(
          _chat_id,
          text: paste_text,
          reply_to_message_id: _reply_msg_id,
          reply_markup: create_markup(_group_id)
        )
      end
    end

    SELECTED   = "■"
    UNSELECTED = "□"

    def_text do
      t("anti_service_msg.desc")
    end

    def create_markup(group_id)
      make_selected_status = ->(delete_target : DeleteTarget) {
        case delete_target
        when DeleteTarget::JoinGroup
          Model::AntiMessage.enabled?(group_id, delete_target) ? UNSELECTED : SELECTED
        when DeleteTarget::LeaveGroup
          Model::AntiMessage.disabled?(group_id, delete_target) ? UNSELECTED : SELECTED
        else
          UNSELECTED
        end
      }
      _markup = Markup.new
      put_item "join_group"
      put_item "leave_group"
      _markup
    end

    macro put_item(name)
      %text = make_selected_status.call(DeleteTarget::{{name.camelcase.id}}) + " " + t("anti_service_msg.{{name.id}}")
      _markup << [Button.new(text: %text, callback_data: "AntiServiceMsg:{{name.id}}")]
    end
  end
end
