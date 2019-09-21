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

    def self.repeated_in_group?(chat_id : Int64, target_msg_id : Int32)
      where { (_from_chat_id == chat_id) & (_target_msg_id == target_msg_id) }.first
    end

    def self.repeated_in_forward?(target_user_id : Int32)
      where { (_target_user_id == target_user_id) & (_status == Status::Accept.value) }.count >= 3
    end

    def self.times_by_target_user(user_id : Int32)
      where { _target_user_id == user_id }.count
    end

    def self.times_by_author(user_id : Int32)
      where { _author_id == user_id }.count
    end

    def self.valid_reported_total(user_id : Int32)
      where { (_target_user_id == user_id) & (_status == Status::Accept.value) }.count
    end

    def self.find_by_post_id(post_id : Int32)
      where { _post_id == post_id }.first
    end
  end
end
