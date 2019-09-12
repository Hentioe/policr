module Policr::Model
  class Group < Jennifer::Model::Base
    alias Status = ReportStatus

    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      title: String,
      link: String?,
      created_at: Time?,
      updated_at: Time?
    )

    has_many :admins, Admin
  end
end
