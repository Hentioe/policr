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
      if v = find_by_chat_id chat_id # 临时性，支持多套问答以后将删除
        update! v.id, title, answers
      else
        create!({
          chat_id: chat_id,
          title:   title,
          answers: answers,
          enabled: true,
        })
      end
    end

    def self.update!(id : Int32 | Nil, title : String, answers : String)
      if qa = find id
        qa.update_columns({:title => title, :answers => answers})
        qa
      else
        raise Exception.new "Not Found"
      end
    end

    def self.find_by_chat_id(chat_id : Int64)
      where { _chat_id == chat_id }.first
    end

    def gen_answers : Tuple(Array(Int32), Array(String))
      lines = self.answers.split("\n", remove_empty: true)

      true_indices = Array(Int32).new
      answers = lines.map_with_index do |line, index|
        true_indices.push(index + 1) if line.starts_with?("+")
        line[1..]
      end
      {true_indices, answers}
    end
  end
end
