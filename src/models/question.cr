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

    def self.all_voting_apply
      where { _use_for == QueUseFor::VotingApplyQuiz.value }.to_a
    end

    def self.enabled_voting_apply(limit : Int32? = nil, offset : Int32? = nil)
      query = where { (_use_for == QueUseFor::VotingApplyQuiz.value) & (_enabled == true) }
      if limit
        query.limit limit
      end
      if offset
        query.offset offset
      end

      query.to_a
    end
  end
end
