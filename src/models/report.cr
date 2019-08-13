module Policr::Model
  class Report < Jennifer::Model::Base
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
      created_at: Time?,
      updated_at: Time?
    )

    has_many :votes, Vote

    def self.check_blacklist(user_id)
      where { (_target_user_id == user_id) & (_status == ReportStatus::Accept.value) }.first
    end

    def self.all_valid(user_id)
      where { (_target_user_id == user_id) & (_status == ReportStatus::Accept.value) }.to_a
    end
  end
end
