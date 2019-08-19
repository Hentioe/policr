module Policr::Model
  class Report < Jennifer::Model::Base
    alias Status = ReportStatus

    with_timestamps

    mapping(
      id: Primary32,
      author_id: Int32,
      post_id: Int32,
      target_snapshot_id: Int32,
      target_user_id: Int32,
      target_msg_id: Int32,
      reason: Int32,
      status: Int32,
      role: Int32,
      from_chat_id: Int64,
      detail: String?,
      appeal_post_id: Int32?,
      created_at: Time?,
      updated_at: Time?
    )

    has_many :votes, Vote
    has_many :appeals, Appeal

    def self.all_valid(user_id)
      where { (_target_user_id == user_id) & (_status == Status::Accept.value) }.to_a
    end

    def self.first_valid(user_id)
      where { (_target_user_id == user_id) & (_status == Status::Accept.value) }.first
    end

    def self.repeat?(chat_id : Int64, target_msg_id : Int32)
      where { (_from_chat_id == chat_id) & (_target_msg_id == target_msg_id) }.first
    end
  end
end
