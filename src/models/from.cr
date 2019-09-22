module Policr::Model
  class From < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      list: String,
      created_at: Time?,
      updated_at: Time?
    )
  end

  private def self.find_by_chat_id(chat_id : Int64)
    where { _chat_id == chat_id }.first
  end

  def self.set_list_content!(chat_id : Int64, content : String)
    if f = find_by_chat_id chat_id
      f.update_column :list, content
    else
      create!({
        chat_id: chat_id,
        list:    content,
        enabled: false,
      })
    end
  end

  def self.enable!(chat_id : Int64)
    if f = find_by_chat_id chat_id
      f.update_column :enabled, true
    else
      raise Exception.new "Uncreated content"
    end
  end

  def self.disable(chat_id : Int64)
    if f = find_by_chat_id chat_id
      f.update_column :enabled, false
    end
  end

  def self.enabled?(chat_id : Int64)
    if (f = find_by_chat_id chat_id) && f.enabled
      f
    else
      nil
    end
  end
end
