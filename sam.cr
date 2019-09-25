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
    desc "迁移清真白名单"
    task "halal_white" do
      prefix = "halal_white"
      puts "#{prefix} started."
      query_by_prefix "#{prefix}_" do |key, value|
        user_id, is_contains =
          if md = /(\d+)$/.match key
            {md[1].to_i, value.to_i == 1}
          else
            {nil, nil}
          end
        if user_id && is_contains
          Policr::Model::HalalWhiteList.add!(user_id, -1)
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
