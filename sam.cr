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
    desc "迁移审核功能启用状态"
    task "enabled_examine" do
      query_by_prefix "enabled_examine_" do |key, value|
        group_id, enabled =
          if md = /(-\d+)$/.match key
            {md[1].to_i64, value.to_i == 1}
          else
            {nil, nil}
          end
        if group_id && enabled
          Policr::Model::Toggle.enable!(group_id, Policr::ToggleTarget::ExamineEnabled)
        end
      end
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
