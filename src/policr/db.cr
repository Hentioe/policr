require "rocksdb"

module Policr::DB
  extend self

  @@db = nil

  def connect(path)
    @@db = RocksDB::DB.new("#{path}/rocks#data#policr")
  end
end
