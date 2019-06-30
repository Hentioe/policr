module Policr::Model
  class Vote < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      author_id: Int64,
      type: Int32,
      weight: {type: Int32, default: 1},
      report_id: Int32,
      created_at: Time?,
      updated_at: Time?
    )

    belongs_to :report, Report
  end
end
