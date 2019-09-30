require "./config/*" # with requiring jennifer and her adapter
require "./db/migrations/*"
require "sam"
load_dependencies "jennifer"

# your custom tasks here
require "rocksdb"
DEFAULT_DATA_DIR = "./data/rocksdb"

namespace "rocksdb" do
  desc "测试数据库连接"
  task "ping" do
    begin
      RocksDB::DB.new(DEFAULT_DATA_DIR, readonly: true)
      puts "pong"
    rescue e : Exception
      puts e.message
    end
  end

  namespace "migrate" do
    desc "迁移验证方式（自定义验证）"
    task "verification_mode_custom" do
      prefix = "custom_text"
      puts "#{prefix} started."
      query_by_prefix "#{prefix}_" do |key, value|
        group_id, content =
          if md = /(-\d+)$/.match key
            {md[1].to_i64, value}
          else
            {nil, nil}
          end
        if group_id && content
          lines = content.split("\n", remove_empty: true)
          title = lines[0]
          answers = lines[1..].join "\n"
          Policr::Model::VerificationMode.update_mode! group_id, Policr::VeriMode::Custom
          Policr::Model::QASuite.add! group_id, title, answers
        end
      end
      puts "#{prefix} done."
    end

    desc "迁移验证方式（算术验证）"
    task "verification_mode_arithmetic" do
      prefix = "dynamic"
      puts "#{prefix} started."
      query_by_prefix "#{prefix}_" do |key, value|
        group_id, enabled =
          if md = /(-\d+)$/.match key
            {md[1].to_i64, value.to_i == 1}
          else
            {nil, nil}
          end
        if group_id && enabled
          Policr::Model::VerificationMode.update_mode! group_id, Policr::VeriMode::Arithmetic
        end
      end
      puts "#{prefix} done."
    end

    desc "迁移验证方式（图片验证）"
    task "verification_mode_image" do
      prefix = "image_captcha"
      puts "#{prefix} started."
      query_by_prefix "#{prefix}_" do |key, value|
        group_id, enabled =
          if md = /(-\d+)$/.match key
            {md[1].to_i64, value.to_i == 1}
          else
            {nil, nil}
          end
        if group_id && enabled
          Policr::Model::VerificationMode.update_mode! group_id, Policr::VeriMode::Image
        end
      end
      puts "#{prefix} done."
    end

    desc "迁移验证方式（棋局验证）"
    task "verification_mode_chessboard" do
      prefix = "chessboard"
      puts "#{prefix} started."
      query_by_prefix "#{prefix}_" do |key, value|
        group_id, enabled =
          if md = /(-\d+)$/.match key
            {md[1].to_i64, value.to_i == 1}
          else
            {nil, nil}
          end
        if group_id && enabled
          Policr::Model::VerificationMode.update_mode! group_id, Policr::VeriMode::Chessboard
        end
      end
      puts "#{prefix} done."
    end

    desc "迁移验证倒计时"
    task "verification_torture_time" do
      prefix = "torture_sec"
      puts "#{prefix} started."
      query_by_prefix "#{prefix}_" do |key, value|
        group_id, sec =
          if md = /(-\d+)$/.match key
            {md[1].to_i64, value.to_i}
          else
            {nil, nil}
          end
        if group_id && sec
          Policr::Model::VerificationMode.set_torture_sec! group_id, sec
        end
      end
      puts "#{prefix} done."
    end
  end
end

def query_by_prefix(prefix)
  db = RocksDB::DB.new(DEFAULT_DATA_DIR, readonly: true)
  iter = db.new_iterator
  iter.first
  while (iter.valid?)
    if iter.key.starts_with? prefix
      kv = {iter.key, iter.value}
      yield kv
    end
    iter.next
  end
  iter.close
end

Sam.help
