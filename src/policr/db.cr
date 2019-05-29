require "rocksdb"
require "ksuid"

module Policr::DB
  extend self

  @@db : RocksDB::DB?

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
    if (db = @@db) && (i = db.get?("enabled_from_#{chat_id.to_s}"))
      i.to_i == 1
    end
  end

  def get_chat_from(chat_id)
    if (db = @@db) && (text = db.get?("from_#{chat_id.to_s}"))
      list = Array(Array(String)).new
      text.split("\n") do |line|
        list += [line.split("-").select { |s| s != "" }.map { |s| s.strip }]
      end
      list
    end
  end

  def enable_examine(chat_id)
    if db = @@db
      db.put("enabled_examine_#{chat_id.to_s}", 1)
    end
  end

  def disable_examine(chat_id)
    if db = @@db
      db.delete("enabled_examine_#{chat_id.to_s}")
    end
  end

  def enable_examine?(chat_id)
    if (db = @@db) && (i = db.get?("enabled_examine_#{chat_id.to_s}"))
      i.to_i == 1
    end
  end

  def set_torture_sec(chat_id, sec)
    if db = @@db
      db.put("torture_sec_#{chat_id.to_s}", sec)
    end
  end

  def get_torture_sec(chat_id)
    if (db = @@db) && (sec = db.get?("torture_sec_#{chat_id.to_s}"))
      sec.to_i
    end
  end

  def trust_admin(chat_id)
    if db = @@db
      db.put("trust_admin_#{chat_id.to_s}", 1)
    end
  end

  def trust_admin?(chat_id)
    if (db = @@db) && (status = db.get?("trust_admin_#{chat_id.to_s}"))
      status.to_i == 1
    end
  end

  def distrust_admin(chat_id)
    if db = @@db
      db.delete("trust_admin_#{chat_id.to_s}")
    end
  end

  def add_to_whitelist(user_id)
    if db = @@db
      db.put("halal_white_#{user_id}", 1)
    end
  end

  def halal_white?(user_id)
    if (db = @@db) && (status = db.get?("halal_white_#{user_id}"))
      status.to_i == 1
    end
  end

  CLEAN_MODE = "clean_mode"

  def clean_mode(chat_id)
    if db = @@db
      db.put("#{CLEAN_MODE}_#{chat_id}", 1)
      db.delete("#{RECORD_MODE}_#{chat_id}")
    end
  end

  def clean_mode?(chat_id)
    if (db = @@db) && (level = db.get?("#{CLEAN_MODE}_#{chat_id}"))
      level.to_i == 1
    end
  end

  RECORD_MODE = "record_mode"

  def record_mode(chat_id)
    if db = @@db
      db.put("#{RECORD_MODE}_#{chat_id}", 1)
      db.delete("#{CLEAN_MODE}_#{chat_id}")
    end
  end

  def record_mode?(chat_id)
    if (db = @@db) && (level = db.get?("#{RECORD_MODE}_#{chat_id}"))
      level.to_i == 1
    end
  end

  def custom_text(chat_id, text)
    if db = @@db
      db.put("custom_text_#{chat_id}", text)
    end
  end

  def custom(chat_id)
    if (db = @@db) && (text = db.get?("custom_text_#{chat_id}"))
      lines = text.split("\n").map { |line| line.strip }.select { |line| line != "" }
      true_index = -1
      answers = lines[1..].map_with_index do |line, index|
        true_index = index + 1 if line.starts_with?("+")
        line[1..]
      end
      {true_index, lines[0], answers}
    end
  end

  MANGA_GROUPS = "manage_groups"

  def push_managed_group(user_id, chat_id)
    if (db = @@db) && (groups = managed_groups(user_id) || Array(String).new)
      groups << chat_id.to_s unless groups.includes?(chat_id.to_s)
      db.put "#{MANGA_GROUPS}_#{user_id}", groups.join(",")
    end
  end

  def delete_managed_group(user_id, chat_id)
    if (db = @@db) && (groups = managed_groups(user_id))
      removed_groups = groups.select { |g| g != chat_id.to_s }.join(",")
      db.put "#{MANGA_GROUPS}_#{user_id}", removed_groups
    end
  end

  def managed_groups(user_id)
    if (db = @@db) && (groups_s = db.get?("#{MANGA_GROUPS}_#{user_id}"))
      groups_s.split(",").select { |g| g.strip != "" }
    end
  end

  FIND_TOKEN_BY_USER = "find_token_by_user"
  FIND_USER_BY_TOKEN = "find_user_by_token"

  def gen_token(user_id)
    if db = @@db
      # 删除已存在的 Token
      if token = db.get?("#{FIND_TOKEN_BY_USER}_#{user_id}")
        db.delete("#{FIND_USER_BY_TOKEN}_#{token}")
      end
      token = KSUID.new.to_s
      # 关联用户和新 Token
      db.put("#{FIND_TOKEN_BY_USER}_#{user_id}", token)
      db.put("#{FIND_USER_BY_TOKEN}_#{token}", user_id)
      # 返回 Token
      token
    end
  end

  def find_user_by_token(token)
    if db = @@db
      db.get?("#{FIND_USER_BY_TOKEN}_#{token}")
    end
  end
end
