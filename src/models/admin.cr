module Policr::Model
  class Admin < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      user_id: Int32,
      fullname: String?,
      created_at: Time?,
      updated_at: Time?
    )

    has_and_belongs_to_many :groups, Group

    def self.fetch_by_user_id!(user_id : Int32, data : NamedTuple? = nil)
      if a = where { _user_id == user_id }.first
        if data
          fullname = data[:fullname]?
          a.update_column(:fullname, fullname) if fullname
        end
        a
      else
        data ||= NamedTuple.new
        data = data.merge({user_id: user_id})
        create! data
      end
    end

    def self.find_by_user_id(user_id : Int32)
      where { _user_id == user_id }.first
    end
  end
end
