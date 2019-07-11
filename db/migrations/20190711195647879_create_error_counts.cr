class CreateErrorCounts < Jennifer::Migration::Base
  def up
    create_table :error_counts do |t|
      # 群组ID
      t.integer :chat_id, {:null => false}
      # 用户ID
      t.integer :user_id, {:null => false}
      # 错误次数
      t.integer :count, {:null => false}

      t.timestamps
    end
  end

  def down
    drop_table :error_counts if table_exists? :error_counts
  end
end
