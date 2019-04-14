module Policr::Cache
  extend self

  enum TortureTimeType
    Sec
    Min
  end

  @@torture_time_msg = Hash(Int32, TortureTimeType).new

  def carving_torture_time_msg_sec(message_id)
    @@torture_time_msg[message_id] = TortureTimeType::Sec
  end

  def carving_torture_time_msg_min(message_id)
    @@torture_time_msg[message_id] = TortureTimeType::Min
  end

  def torture_time_msg?(message_id)
    @@torture_time_msg[message_id]?
  end
end
