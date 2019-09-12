module Policr::Model
  class Admin < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      user_id: Int32,
      is_owner: Bool,
      group_id: Int32,
      created_at: Time?,
      updated_at: Time?
    )

    belongs_to :group, Group
  end
end
