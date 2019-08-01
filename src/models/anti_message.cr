module Policr::Model
  class AntiMessage < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      delete_target: Int32,
      status: Int32,
      created_at: Time?,
      updated_at: Time?
    )

    alias DeleteTarget = AntiMessageDeleteTarget

    def self.add!(group_id, delete_target : DeleteTarget)
      create!({
        chat_id:       group_id.to_i64,
        delete_target: delete_target.value,
        status:        EnableStatus::TurnOff.value,
      })
    end

    def self.enable!(group_id, delete_target)
      cm = find group_id, delete_target
      cm ||= add! group_id, delete_target
      cm.update_column(:status, EnableStatus::TurnOn.value)
    end

    def self.disable!(group_id, delete_target)
      cm = find group_id, delete_target
      cm ||= add! group_id, delete_target
      cm.update_column(:status, EnableStatus::TurnOff.value)
    end

    def self.find(group_id, delete_target : DeleteTarget)
      where { (_chat_id == group_id) & (_delete_target == delete_target.value) }.first
    end

    def self.enabled?(group_id, delete_target)
      if am = find(group_id, delete_target)
        am.status == EnableStatus::TurnOn.value
      else
        false
      end
    end

    def self.disabled?(group_id, delete_target)
      if am = find(group_id, delete_target)
        am.status == EnableStatus::TurnOff.value
      else
        false
      end
    end

    def self.working(group_id, delete_target, default = false)
      enabled =
        if default
          disabled? group_id, delete_target
        else
          enabled? group_id, delete_target
        end
      yield if enabled
    end
  end
end
