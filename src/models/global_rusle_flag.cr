module Policr::Model
  class GlobalRuleFlag < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      enabled: Bool,
      reported: Bool,
      action: Int32,
      created_at: Time?,
      updated_at: Time?
    )

    def self.find_by_chat_id(chat_id : Int64)
      where { _chat_id == chat_id }.first
    end

    def self.fetch_by_chat_id!(chat_id : Int64)
      find_by_chat_id(chat_id) || create!({
        chat_id:  chat_id,
        enabled:  false,
        reported: false,
        action:   HitAction::Restrict.value,
      })
    end

    def self.enable!(chat_id : Int64)
      flag = fetch_by_chat_id!(chat_id)
      flag.update_column :enabled, true

      flag
    end

    def self.enabled?(chat_id : Int64)
      where { (_chat_id == chat_id) & (_enabled == true) }.first
    end

    def self.disable(chat_id : Int64)
      if flag = find_by_chat_id chat_id
        flag.update_column :enabled, false
      end
    end

    def self.enable_report!(chat_id : Int64)
      if (flag = enabled? chat_id) && flag.enabled
        flag.update_column :reported, true
      else
        raise Exception.new "Please subscribe first"
      end
    end

    def self.disable_report(chat_id : Int64)
      if flag = find_by_chat_id chat_id
        flag.update_column :reported, false
      end
    end

    def self.reported?(chat_id : Int64)
      where { (_chat_id == chat_id) & (_reported == true) }.first
    end

    def self.action_is?(chat_id : Int64, action : HitAction)
      if flag = find_by_chat_id chat_id
        flag.action == action.value
      end
    end

    def self.switch_action!(chat_id : Int64, action : HitAction)
      if flag = enabled? chat_id
        flag.update_column :action, action.value
      else
        raise Exception.new "Please subscribe first"
      end
    end
  end
end
