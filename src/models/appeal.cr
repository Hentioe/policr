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

    def self.valid_times(user_id : Int32)
      where { (_author_id == user_id) & (_done == true) }.count
    end

    def self.delete_by_report_id(report_id : Int32)
      where { (_report_id == report_id) }.delete
    end
  end
end
