module Policr::Model
  class PrivateMenu < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      msg_id: Int32,
      group_id: Int64,
      created_at: Time?,
      updated_at: Time?
    )

    def self.add(chat_id, msg_id, group_id)
      create({
        chat_id:  chat_id.to_i64,
        msg_id:   msg_id,
        group_id: group_id.to_i64,
      })
    end

    def self.find(chat_id, msg_id)
      where { (_chat_id == chat_id) & (_msg_id == msg_id) }.first
    end

    def self.find_group_id(chat_id, msg_id)
      if pm = find(chat_id, msg_id)
        pm.group_id
      end
    end
  end
end
