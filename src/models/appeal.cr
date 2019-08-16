module Policr::Model
  class Appeal < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      author_id: Int32,
      done: Bool,
      report_id: Int32,
      created_at: Time?,
      updated_at: Time?
    )

    belongs_to :report, Report
  end
end
