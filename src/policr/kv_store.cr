require "rocksdb"
require "ksuid"

module Policr::KVStore
  extend self

  @@db : RocksDB::DB?

  def connect(path)
    @@db = RocksDB::DB.new("#{path}/rocksdb")
  end

  TRUE_INDEX = "true_index" # 已废弃，储存正确答案索引

  macro def_toggle(name, key = name, disable = 0, enable = 0, conflicts = [] of String)
    {% if enable == 1 %}
      def enable_{{name.id}}(chat_id)
        if db = @@db
          db.put "{{key.id}}_#{chat_id}", 1
          {% for conflict in conflicts %}
            disable_{{conflict.id}} chat_id
          {% end %}
        end
      end

      def disable_{{name.id}}(chat_id)
        if db = @@db
          db.delete "{{key.id}}_#{chat_id}"
        end
      end

      def enabled_{{name.id}}?(chat_id)
        if (db = @@db) && (i = db.get?("{{key.id}}_#{chat_id}"))
          i.to_i == 1
        else
          false
        end
      end
    {% elsif disable == 1 %}
      def disable_{{name.id}}(chat_id)
        if db = @@db
          db.put "{{key.id}}_#{chat_id}", 1
        end
      end

      def enable_{{name.id}}(chat_id)
        if db = @@db
          db.delete "{{key.id}}_#{chat_id}"
        end
      end

      def disabled_{{name.id}}?(chat_id)
        if (db = @@db) && (i = db.get?("{{key.id}}_#{chat_id}"))
          i.to_i == 1
        else
          false
        end
      end
    {% end %}
  end

  WELCOME_LINK_PREVIEW = "welcome_link_preview"
  ENABLED_FROM         = "enabled_from"
  ENABLED_EXAMINE      = "enabled_examine"
  TRUST_ADMIN          = "trust_admin"
  DYNAMIC_CAPTCHA      = "dynamic"
  CHESSBOARD_CAPTCHA   = "chessboard"
  IMAGE_CAPTCHA        = "image_captcha"
  FAULT_TOLERANCE      = "fault_tolerance"
  ENABLE_WELCOME       = "enabled_welcome"
  CLEAN_MODE           = "clean_mode"
  RECORD_MODE          = "record_mode"

  def_toggle {{WELCOME_LINK_PREVIEW}}, disable: 1
  def_toggle "from", key: {{ENABLED_FROM}}, enable: 1
  def_toggle "examine", key: {{ENABLED_EXAMINE}}, enable: 1
  def_toggle {{TRUST_ADMIN}}, enable: 1
  def_toggle {{FAULT_TOLERANCE}}, enable: 1
  def_toggle "welcome", key: {{ENABLE_WELCOME}}, enable: 1

  def_toggle "dynamic_captcha", key: {{DYNAMIC_CAPTCHA}}, enable: 1, conflicts: [
    "custom_captcha", "chessboard_captcha", "image_captcha",
  ]
  def_toggle "chessboard_captcha", key: {{CHESSBOARD_CAPTCHA}}, enable: 1, conflicts: [
    "custom_captcha", "dynamic_captcha", "image_captcha",
  ]
  def_toggle "image_captcha", enable: 1, conflicts: [
    "custom_captcha", "chessboard_captcha", "dynamic_captcha",
  ]

  def_toggle {{CLEAN_MODE}}, enable: 1, conflicts: ["record_mode"]
  def_toggle {{RECORD_MODE}}, enable: 1, conflicts: ["clean_mode"]

  def put_chat_from(chat_id, text)
    if db = @@db
      db.put("from_#{chat_id.to_s}", text)
    end
  end

  def get_from(chat_id)
    if (db = @@db) && (text = db.get?("from_#{chat_id.to_s}"))
      list = Array(Array(String)).new
      text.split("\n") do |line|
        list += [line.split("-").select { |s| s != "" }.map { |s| s.strip }]
      end
      list
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

  CUSTOM_TEXT = "custom_text"

  def custom_text(chat_id, text)
    if db = @@db
      db.put("#{CUSTOM_TEXT}_#{chat_id}", text)
      disable_dynamic_captcha chat_id
      disable_image_captcha chat_id
      disable_chessboard_captcha chat_id
    end
  end

  def custom(chat_id)
    if (db = @@db) && (text = db.get?("#{CUSTOM_TEXT}_#{chat_id}"))
      # 删除动态验证
      db.delete("#{DYNAMIC_CAPTCHA}_#{chat_id}")
      lines = text.split("\n").map { |line| line.strip }.select { |line| line != "" }
      true_indices = Array(Int32).new
      answers = lines[1..].map_with_index do |line, index|
        true_indices.push(index + 1) if line.starts_with?("+")
        line[1..]
      end
      {true_indices, lines[0], answers}
    end
  end

  def disable_custom_captcha(chat_id)
    if db = @@db
      db.delete "#{CUSTOM_TEXT}_#{chat_id}"
    end
  end

  def default(chat_id)
    if db = @@db
      disable_custom_captcha chat_id
      disable_dynamic_captcha chat_id
      disable_image_captcha chat_id
      disable_chessboard_captcha chat_id
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

  WELCOME = "welcome"

  def set_welcome(chat_id, content)
    if db = @@db
      db.put "#{WELCOME}_#{chat_id}", content
    end
  end

  def get_welcome(chat_id)
    if db = @@db
      db.get? "#{WELCOME}_#{chat_id}"
    end
  end
end
