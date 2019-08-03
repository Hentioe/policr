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
      list = list.select { |format| !cur_list.includes?(format) }
      list += cur_list

      raise "Too many specified formats" if list.size > 8

      list = list.map do |extension_name|
        if extension_name.starts_with?(".")
          extension_name.gsub(/^\./, "")
        else
          extension_name
        end
      end

      fl = find(group_id) || add!(group_id, list)
      fl.update_column(:list, list.join(","))
    end

    def self.delete_format(group_id, extension_name)
      if fl = find(group_id)
        list = fl.list.split(",")
        list = list.select { |format| format != extension_name.strip }
        fl.update_column(:list, list.join(","))
      end
    end

    def self.clear(group_id)
      where { _chat_id == group_id.to_i64 }.delete
    end
  end
end
