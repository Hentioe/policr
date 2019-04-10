require "rocksdb"

module Policr::DB
  extend self

  @@db = nil

  def conn?
    if db = @@db
      yield db
    end
  end

  def connect(path)
    @@db = RocksDB::DB.new("#{path}/rocks#data#policr")
  end

  private def put(key, value)
    if db = @@db
      db.put(key, value)
    end
  end

  def put_chat_from(chat_id, text)
    if db = @@db
      enable_chat_from(chat_id)
      db.put("from_#{chat_id.to_s}", text)
    end
  end

  def enable_chat_from(chat_id)
    if db = @@db
      db.put("enabled_from_#{chat_id.to_s}", 1)
    end
  end

  def disable_chat_from(chat_id)
    if db = @@db
      db.delete("enabled_from_#{chat_id.to_s}")
    end
  end

  def enabled_from?(chat_id)
    if db = @@db
      db.get("enabled_from_#{chat_id.to_s}")
    end
  end

  def get_chat_from(chat_id)
    return unless enabled_from?(chat_id)
    if (db = @@db) && (text = db.get?("from_#{chat_id.to_s}"))
      list = Array(Array(String)).new
      text.split("\n") do |line|
        list += [line.split("-").select { |s| s != "" }.map { |s| s.strip }]
      end
      list
    end
  end

  def enable_examine(chat_id)
    conn? do |db|
      db.put("enabled_examine_#{chat_id.to_s}", 1)
    end
  end

  def disable_examine(chat_id)
    conn? do |db|
      db.delete("enabled_examine_#{chat_id.to_s}")
    end
  end

  def enable_examine?(chat_id)
    conn? do |db|
      db.get("enabled_examine_#{chat_id.to_s}")
    end
  end
end
