require "rocksdb"

module Policr::KVStore
  # extend self

  # @@db : RocksDB::DB?

  # def connect(path)
  #   @@db = RocksDB::DB.new("#{path}/rocksdb")
  # end

  # TRUE_INDEX = "true_index" # 已废弃，储存正确答案索引

  # macro def_toggle(name, key = "none", disable = 0, enable = 0, conflicts = [] of String)
  #   {% if enable == 1 %}
  #     def enable_{{name.id}}(chat_id)
  #       if db = @@db
  #         db.put "{{key.id}}_#{chat_id}", 1
  #         {% for conflict in conflicts %}
  #           disable_{{conflict.id}} chat_id
  #         {% end %}
  #       end
  #     end

  #     def disable_{{name.id}}(chat_id)
  #       if db = @@db
  #         db.delete "{{key.id}}_#{chat_id}"
  #       end
  #     end

  #     def enabled_{{name.id}}?(chat_id) : Bool
  #       if (db = @@db) && (i = db.get?("{{key.id}}_#{chat_id}"))
  #         i.to_i == 1
  #       else
  #         false
  #       end
  #     end
  #   {% elsif disable == 1 %}
  #     def disable_{{name.id}}(chat_id)
  #       if db = @@db
  #         db.put "{{key.id}}_#{chat_id}", 1
  #       end
  #     end

  #     def enable_{{name.id}}(chat_id)
  #       if db = @@db
  #         db.delete "{{key.id}}_#{chat_id}"
  #       end
  #     end

  #     def disabled_{{name.id}}?(chat_id)
  #       if (db = @@db) && (i = db.get?("{{key.id}}_#{chat_id}"))
  #         i.to_i == 1
  #       else
  #         false
  #       end
  #     end
  #   {% end %}
  # end

  # 综合设置菜单
  # def_toggle "examine", key: enabled_examine, enable: 1
  # def_toggle "trust_admin", key: trust_admin, enable: 1
  # def_toggle "privacy_setting", key: privacy_setting, enable: 1
  # def_toggle "record_mode", key: record_mode, enable: 1
  # def_toggle "from", key: enabled_from, enable: 1
  # def_toggle "fault_tolerance", key: fault_tolerance, enable: 1

  # 欢迎消息设置
  # def_toggle "welcome", key: enabled_welcome, enable: 1
  # def_toggle "welcome_link_preview", key: welcome_link_preview, disable: 1

  # 验证方式
  # def_toggle "dynamic_captcha", key: dynamic, enable: 1, conflicts: [
  #   "custom_captcha", "chessboard_captcha", "image_captcha",
  # ]
  # def_toggle "chessboard_captcha", key: chessboard, enable: 1, conflicts: [
  #   "custom_captcha", "dynamic_captcha", "image_captcha",
  # ]
  # def_toggle "image_captcha", key: image_captcha, enable: 1, conflicts: [
  #   "custom_captcha", "chessboard_captcha", "dynamic_captcha",
  # ]

  # def put_chat_from(chat_id, text)
  #   if db = @@db
  #     db.put("from_#{chat_id.to_s}", text)
  #   end
  # end

  # def get_from(chat_id)
  #   if (db = @@db) && (text = db.get?("from_#{chat_id.to_s}"))
  #     list = Array(Array(String)).new
  #     text.split("\n") do |line|
  #       list += [line.split("-").select { |s| s != "" }.map { |s| s.strip }]
  #     end
  #     list
  #   end
  # end

  # def set_torture_sec(chat_id, sec)
  #   if db = @@db
  #     db.put("torture_sec_#{chat_id.to_s}", sec)
  #   end
  # end

  # def get_torture_sec(chat_id)
  #   if (db = @@db) && (sec = db.get?("torture_sec_#{chat_id.to_s}"))
  #     sec.to_i
  #   end
  # end

  # def add_to_whitelist(user_id)
  #   if db = @@db
  #     db.put("halal_white_#{user_id}", 1)
  #   end
  # end

  # def halal_white?(user_id)
  #   if (db = @@db) && (status = db.get?("halal_white_#{user_id}"))
  #     status.to_i == 1
  #   end
  # end

  # CUSTOM_TEXT = "custom_text"

  # def custom_text(chat_id, text)
  #   if db = @@db
  #     db.put("#{CUSTOM_TEXT}_#{chat_id}", text)
  #     disable_dynamic_captcha chat_id
  #     disable_image_captcha chat_id
  #     disable_chessboard_captcha chat_id
  #   end
  # end

  # def custom(chat_id)
  #   if (db = @@db) && (text = db.get?("#{CUSTOM_TEXT}_#{chat_id}"))
  #     lines = text.split("\n").map { |line| line.strip }.select { |line| line != "" }
  #     true_indices = Array(Int32).new
  #     answers = lines[1..].map_with_index do |line, index|
  #       true_indices.push(index + 1) if line.starts_with?("+")
  #       line[1..]
  #     end
  #     {true_indices, lines[0], answers}
  #   end
  # end

  # def disable_custom_captcha(chat_id)
  #   if db = @@db
  #     db.delete "#{CUSTOM_TEXT}_#{chat_id}"
  #   end
  # end

  # def default(chat_id)
  #   if db = @@db
  #     disable_custom_captcha chat_id
  #     disable_dynamic_captcha chat_id
  #     disable_image_captcha chat_id
  #     disable_chessboard_captcha chat_id
  #   end
  # end

  # WELCOME = "welcome"

  # def set_welcome(chat_id, content)
  #   if db = @@db
  #     db.put "#{WELCOME}_#{chat_id}", content
  #   end
  # end

  # def get_welcome(chat_id)
  #   if db = @@db
  #     db.get? "#{WELCOME}_#{chat_id}"
  #   end
  # end
end
