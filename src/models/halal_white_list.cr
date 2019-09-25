module Policr::Model
  class HalalWhiteList < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      user_id: Int32,
      creator_id: Int32,
      created_at: Time?,
      updated_at: Time?
    )

    def self.contains?(user_id : Int32)
      where { _user_id == user_id }.first
    end

    def self.add!(user_id : Int32, creator_id : Int32)
      if hwl = contains? user_id
        hwl
      else
        create!({
          user_id:    user_id,
          creator_id: creator_id,
        })
      end
    end
  end
end
