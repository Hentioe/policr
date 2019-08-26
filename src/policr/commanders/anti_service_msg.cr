module Policr
  commander AntiServiceMsg do
    def handle(msg, from_nav)
      reply_menu do
        create_menu({
          text:         paste_text,
          reply_markup: paste_markup,
        })
      end
    end

    SELECTED   = "■"
    UNSELECTED = "□"

    def_text do
      t("anti_service_msg.desc")
    end

    def_markup do
      make_selected_status = ->(delete_target : ServiceMessage) {
        case delete_target
        when ServiceMessage::JoinGroup
          Model::AntiMessage.disabled?(_group_id, delete_target) ? UNSELECTED : SELECTED
        when ServiceMessage::LeaveGroup
          Model::AntiMessage.disabled?(_group_id, delete_target) ? UNSELECTED : SELECTED
        else
          UNSELECTED
        end
      }
      put_item "join_group"
      put_item "leave_group"
    end

    macro put_item(name)
      %text = make_selected_status.call(ServiceMessage::{{name.camelcase.id}}) + " " + t("anti_service_msg.{{name.id}}")
      _markup << [Button.new(text: %text, callback_data: "AntiServiceMsg:{{name.id}}")]
    end
  end
end
