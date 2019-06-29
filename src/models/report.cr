module Policr::Model
  class Report < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      author_id: Int64,
      post_id: Int32,
      target_id: Int64,
      reason: Int32,
      status: Int32,
      role: Int32,
      from_chat: Int64?,
      created_at: Time?,
      updated_at: Time?
    )
  end
end
