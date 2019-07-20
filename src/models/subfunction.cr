module Policr::Model
  class Subfunction < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      type: Int32,
      status: Int32,
      created_at: Time?,
      updated_at: Time?
    )

    def self.find_or_create!(group_id, func_type, data : NamedTuple? = nil)
      sf = where { (_chat_id == group_id) & (_type == func_type.value) }.first
      sf = sf || create!(data)
    end

    def self.disabled?(chat_id, type)
      Subfunction.where { (_chat_id == chat_id) & (_type == type.value) & (_status == EnableStatus::TurnOff.value) }.first != nil
    end
  end
end
