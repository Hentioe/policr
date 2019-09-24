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
    desc "迁移欢迎消息内容"
    task "welcome" do
      prefix = "welcome"
      puts "#{prefix} started."
      query_by_prefix "#{prefix}_" do |key, value|
        group_id, content =
          if md = /(-\d+)$/.match key
            {md[1].to_i64, value}
          else
            {nil, nil}
          end
        if group_id && content
          Policr::Model::Welcome.set_content!(group_id, content)
        end
      end
      puts "#{prefix} done."
    end

    desc "迁移欢迎消息启用状态"
    task "enabled_welcome" do
      prefix = "enabled_welcome"
      puts "#{prefix} started."
      query_by_prefix "#{prefix}_" do |key, value|
        group_id, enabled =
          if md = /(-\d+)$/.match key
            {md[1].to_i64, value.to_i == 1}
          else
            {nil, nil}
          end
        if group_id && enabled
          Policr::Model::Welcome.enable!(group_id)
        end
      end
      puts "#{prefix} done."
    end

    desc "迁移欢迎消息链接预览禁用状态"
    task "welcome_link_preview" do
      prefix = "welcome_link_preview"
      puts "#{prefix} started."
      query_by_prefix "#{prefix}_" do |key, value|
        group_id, disabled =
          if md = /(-\d+)$/.match key
            {md[1].to_i64, value.to_i == 1}
          else
            {nil, nil}
          end
        if group_id && disabled
          Policr::Model::Welcome.disable_link_preview(group_id)
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
