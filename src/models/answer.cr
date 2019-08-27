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
  end
end
