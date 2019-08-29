module Policr::Model
  class Answer < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      name: String,
      corrected: Bool,
      question_id: Int32,
      created_at: Time?,
      updated_at: Time?
    )

    belongs_to :question, Question

    def self.corrected?(question_id : Int32, answer_id : Int32)
      if a = find(answer_id)
        a.corrected && a.question_id == question_id
      end
    end
  end
end
