class CreateBlockContents < Jennifer::Migration::Base
  def up
    create_table :block_contents do |t|
      # 群组ID
      t.integer :chat_id, {:null => false}
      # 版本
      t.string :version, {:null => false}
      # 表达式
      t.integer :expression, {:null => false}

      t.timestamps
    end
  end

  def down
    drop_table :block_contents if table_exists? :block_contents
  end
end
