module Policr::Model
  class Question < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      title: String,
      desc: String?,
      note: String?,
      use_for: Int32,
      enabled: Bool,
      created_at: Time?,
      updated_at: Time?
    )

    has_many :answers, Answer
  end
end
