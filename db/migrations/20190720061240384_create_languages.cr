class CreateLanguages < Jennifer::Migration::Base
  def up
    create_table :languages do |t|
      # 群组ID
      t.integer :chat_id, {:null => false}
      # 语言码
      t.integer :code, {:null => false}
      # 自动匹配
      t.integer :auto, {:null => false}

      t.timestamps
    end
  end

  def down
    drop_table :languages if table_exists? :languages
  end
end
