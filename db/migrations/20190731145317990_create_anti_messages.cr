class CreateAntiMessages < Jennifer::Migration::Base
  def up
    create_table :anti_messages do |t|
      # 群组ID
      t.integer :chat_id, {:null => false}
      # 删除目标
      t.integer :delete_target, {:null => false}

      t.timestamps
    end
  end

  def down
    drop_table :anti_messages if table_exists? :anti_messages
  end
end
