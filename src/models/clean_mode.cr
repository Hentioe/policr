module Policr::Model
  class CleanMode < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      delete_target: Int32,
      delay_sec: Int32?,
      status: Int32,
      created_at: Time?,
      updated_at: Time?
    )

    belongs_to :report, Report
  end
end
