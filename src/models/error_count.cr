module Policr::Model
  class ErrorCount < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      user_id: Int64,
      count: {type: Int32, default: 0},
      created_at: Time?,
      updated_at: Time?
    )

    def self.one_time(chat_id, user_id)
      ec = where { (_chat_id == chat_id) & (_user_id == user_id) }.first
      ec ||= create({
        chat_id: chat_id.to_i64,
        user_id: user_id.to_i64,
      })
      ec.update_column(:count, (ec.count + 1))
    end

    def self.counting(chat_id, user_id)
      if ec = where { (_chat_id == chat_id) & (_user_id == user_id) }.first
        ec.count
      else
        0
      end
    end

    def self.destory(chat_id, user_id)
      where { (_chat_id == chat_id.to_i64) & (_user_id == user_id.to_i64) }.delete
    end
  end
end
