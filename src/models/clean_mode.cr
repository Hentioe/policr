module Policr::Model
  class CleanMode < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      delete_target: Int32,
      delay_sec: Int32?,
      status: Int32,
      created_at: Time?,
      updated_at: Time?
    )

    belongs_to :report, Report

    def self.working(chat_id, target, &block)
      cm = CleanMode.where { (_chat_id == chat_id) & (_delete_target == target.value) }.first
      if cm && cm.status == EnableStatus::TurnOn.value # 如果存在本消息类型的延迟删除设置，设定定时任务
        delay_sec = cm.delay_sec || DEFAULT_DELAY_DELETE
        Schedule.after(delay_sec.seconds, &block)
      end
    end
  end
end
