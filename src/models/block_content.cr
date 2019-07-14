module Policr::Model
  class BlockContent < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      version: String,
      expression: String,
      created_at: Time?,
      updated_at: Time?
    )

    def self.find(chat_id)
      where { (_chat_id == chat_id) }.first
    end

    def self.update_expression(chat_id, expression)
      bc = find(chat_id)
      bc ||= create({
        chat_id:    chat_id.to_i64,
        version:    "v1",
        expression: expression,
      })

      bc.update_column(:expression, expression)
    end
  end
end
