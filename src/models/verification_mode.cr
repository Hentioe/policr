module Policr::Model
  class VerificationMode < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      mode: Int32,
      sec: Int32?,
      created_at: Time?,
      updated_at: Time?
    )

    def self.is?(chat_id : Int64, mode : VeriMode)
      if v = find_by_chat_id chat_id
        v.mode == mode.value
        v
      end
    end

    def self.get_mode(chat_id : Int64, default : VeriMode)
      if v = find_by_chat_id chat_id
        VeriMode.from_value?(v.mode) || default
      else
        default
      end
    end

    def self.find_by_chat_id(chat_id : Int64)
      where { _chat_id == chat_id }.first
    end

    def self.fetch_by_chat_id(chat_id : Int64)
      find_by_chat_id(chat_id) || safe_save(chat_id)
    end

    def self.safe_save(chat_id : Int64)
      begin
        create!({
          chat_id: chat_id,
          mode:    VeriMode::Default.value,
        })
      rescue
        VerificationMode.new({
          chat_id: chat_id,
          mode:    VeriMode::Default.value,
        }, new_record: false)
      end
    end

    def self.update_mode!(chat_id : Int64, mode : VeriMode)
      if v = find_by_chat_id chat_id
        v.update_column :mode, mode.value
      else
        create!({
          chat_id: chat_id,
          mode:    mode.value,
        })
      end
    end

    def self.get_torture_sec(chat_id : Int64, default : Int32) : Int32
      fetch_by_chat_id(chat_id).sec || default
    end

    def self.set_torture_sec!(chat_id : Int64, sec : Int32)
      if v = find_by_chat_id chat_id
        v.update_column :sec, sec
      else
        create!({
          chat_id: chat_id,
          mode:    VeriMode::Default.value,
          sec:     sec,
        })
      end
    end
  end
end
