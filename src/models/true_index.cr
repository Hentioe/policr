module Policr::Model
  class TrueIndex < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      msg_id: Int32,
      indices: String?,
      created_at: Time?,
      updated_at: Time?
    )

    def self.add(chat_id, msg_id, indices)
      create({
        chat_id: chat_id,
        msg_id:  msg_id,
        indices: indices.join(","),
      })
    end

    def self.get(chat_id, msg_id)
      where { (_chat_id == chat_id) & (_msg_id == msg_id) }.first
    end

    def self.contains?(chat_id, msg_id, index)
      if (ti = get(chat_id, msg_id)) && (indices = ti.indices)
        indices.split(",").includes?(index)
      end
    end
  end
end
