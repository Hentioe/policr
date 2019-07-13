module Policr::Model
  class MaxLength < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      total: Int32?,
      rows: Int32?,
      created_at: Time?,
      updated_at: Time?
    )

    def self.update(chat_id, column, val)
      ml = where { _chat_id == chat_id }.first
      ml ||= create({
        chat_id: chat_id.to_i64,
      })
      ml.update_column(column, val)
    end

    def self.find(chat_id)
      where { _chat_id == chat_id }.first
    end

    def self.update_total(chat_id, val)
      update(chat_id, :total, val)
    end

    def self.update_rows(chat_id, val)
      update(chat_id, :rows, val)
    end

    def self.values(chat_id)
      if ml = where { _chat_id == chat_id }.first
        {ml.total, ml.rows}
      else
        {nil, nil}
      end
    end
  end
end
