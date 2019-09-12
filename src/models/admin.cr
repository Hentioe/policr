module Policr::Model
  class Admin < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      user_id: Int32,
      is_owner: Bool,
      created_at: Time?,
      updated_at: Time?
    )

    has_and_belongs_to_many :groups, Group
  end
end
