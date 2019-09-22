module Policr::Model
  class Toggle < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      target: Int32,
      enabled: Bool,
      created_at: Time?,
      updated_at: Time?
    )

    private macro def_is_enabled(target_s)
      def self.{{target_s.id}}?(chat_id : Int64) : Bool
        enabled? chat_id, ToggleTarget::{{target_s.id.camelcase}}
      end
    end

    def_is_enabled "examine_enabled"
    def_is_enabled "trusted_admin"

    def self.enabled?(chat_id : Int, target : ToggleTarget) : Bool
      if t = where { (_chat_id == chat_id.to_i64) & (_target == target.value) }.first
        t.enabled
      else
        false
      end
    end

    def self.disabled?(chat_id : Int, target : ToggleTarget) : Bool
      if t = where { (_chat_id == chat_id.to_i64) & (_target == target.value) }.first
        !t.enabled
      else
        false
      end
    end

    private def self.switch!(chat_id : Int, target : ToggleTarget, enabled : Bool)
      if t = where { (_chat_id == chat_id.to_i64) & (_target == target.value) }.first
        t.update_column :enabled, enabled
        t
      else
        create!({
          chat_id: chat_id.to_i64,
          target:  target.value,
          enabled: enabled,
        })
      end
    end

    def self.enable!(chat_id, target)
      switch! chat_id, target, true
    end

    def self.disable!(chat_id, target)
      switch! chat_id, target, false
    end
  end
end
