module Policr::Model
  class Template < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      content: String,
      enabled: Bool,
      created_at: Time?,
      updated_at: Time?
    )

    private def self.exists?(chat_id : Int64)
      where { _chat_id == chat_id }.first
    end

    private def self.change_status(chat_id : Int64, enabled : Bool)
      if t = exists? chat_id
        t.update_column :enabled, enabled
      end
    end

    def self.enable(chat_id)
      change_status chat_id, true
    end

    def self.disable(chat_id)
      change_status chat_id, false
    end

    def self.enabled?(chat_id : Int64)
      where { (_chat_id == chat_id) & (_enabled == true) }.first
    end

    def self.set_content!(chat_id : Int64, content : String)
      if t = exists?(chat_id)
        t.update_column :content, content
        t
      else
        create!({:chat_id => chat_id, :content => content, :enabled => false})
      end
    end
  end
end
