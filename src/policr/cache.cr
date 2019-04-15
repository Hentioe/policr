module Policr::Cache
  extend self

  enum TortureTimeType
    Sec
    Min
  end

  enum VerifyStatus
    Init
    Pass
    Slow
  end

  @@torture_time_msg = Hash(Int32, TortureTimeType).new
  @@from_setting_msg = Set(Int32).new
  @@verify_status = Hash(Int32, VerifyStatus).new

  def carving_torture_time_msg_sec(message_id)
    @@torture_time_msg[message_id] = TortureTimeType::Sec
  end

  def carving_torture_time_msg_min(message_id)
    @@torture_time_msg[message_id] = TortureTimeType::Min
  end

  def torture_time_msg?(message_id)
    @@torture_time_msg[message_id]?
  end

  def carying_from_setting_msg(message_id)
    @@from_setting_msg << message_id
  end

  def from_setting_msg?(message_id)
    @@from_setting_msg.includes? message_id
  end

  def verify_passed(user_id)
    @@verify_status[user_id] = VerifyStatus::Pass
  end

  def verify_init(user_id)
    @@verify_status[user_id] = VerifyStatus::Init
  end

  def verify_slowed(user_id)
    @@verify_status[user_id] = VerifyStatus::Slow
  end

  def verify?(user_id)
    @@verify_status[user_id]?
  end

  def verify_status_clear(user_id)
    @@verify_status.delete user_id
  end
end
