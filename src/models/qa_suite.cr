module Policr::Model
  class QASuite < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      title: String,
      answers: String,
      enabled: Bool,
      created_at: Time?,
      updated_at: Time?
    )

    def self.add!(chat_id : Int64, title : String, answers : String)
      create!({
        chat_id: chat_id,
        title:   title,
        answers: answers,
        enabled: true,
      })
    end

    def self.update!(id : Int32 | Nil, title : String, answers : String)
      if qa = find id
        qa.update_columns({:title => title, :answers => answers})
      else
        raise Exception.new "Not Found"
      end
    end

    def self.find_by_chat_id(chat_id : Int64)
      where { _chat_id == chat_id }.first
    end
  end
end
