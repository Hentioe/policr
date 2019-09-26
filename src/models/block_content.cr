module Policr::Model
  class BlockContent < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      version: String,
      alias_s: String,
      expression: String,
      is_enabled: Bool,
      created_at: Time?,
      updated_at: Time?
    )

    def self.enabled?(chat_id : Int64)
      where { (_chat_id == chat_id) & (_is_enabled == true) }.count > 0
    end

    def self.disable_all(chat_id : Int64)
      where { (_chat_id == chat_id) & (_is_enabled == true) }.update { {:is_enabled => false} }
    end

    def self.update!(id : Int32, expression : String, alias_s : String)
      if bc = find id
        bc.update_columns({
          :expression => expression,
          :alias_s    => alias_s,
        })
        bc
      else
        raise Exception.new "Not Found"
      end
    end

    def self.add!(chat_id : Int64, expression : String, alias_s : String)
      create!({
        chat_id:    chat_id,
        version:    "v2",
        alias_s:    alias_s,
        expression: expression,
        is_enabled: false,
      })
    end

    def self.load_list(chat_id : Int64)
      where { (_chat_id == chat_id) & (_is_enabled == true) }.offset(0).limit(5).to_a
    end

    def self.counts(chat_id : Int64) : Int
      where { _chat_id == chat_id }.count
    end
  end
end
