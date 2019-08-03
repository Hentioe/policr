module Policr::Model
  class FormatLimit < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      list: String,
      created_at: Time?,
      updated_at: Time?
    )

    def self.add!(group_id, list : Array(String))
      create!({
        chat_id: group_id.to_i64,
        list:    list.join(","),
      })
    end

    def self.find(group_id)
      where { _chat_id == group_id.to_i64 }.first
    end

    def self.get_format_list(group_id)
      if fl = find(group_id)
        fl.list.split(",")
      else
        [] of String
      end
    end

    def self.includes?(group_id, format_name)
      get_format_list(group_id).includes? format_name
    end

    def self.put_list!(group_id, list)
      cur_list = get_format_list(group_id)
      list += cur_list

      fl = find(group_id) || add!(group_id, list)
      fl.update_column(:list, list.join(","))
    end

    def self.clear(group_id)
      where { _chat_id == group_id.to_i64 }.delete
    end
  end
end
