class CreateCleanMode < Jennifer::Migration::Base
  def up
    create_table :clean_modes do |t|
      # 群组ID
      t.integer :chat_id, {:null => false}
      # 删除目标
      t.integer :delete_target, {:null => false}
      # 延迟时间（秒）
      t.integer :delay_sec
      # 启用状态
      t.integer :status, {:null => false}

      t.timestamps
    end
  end

  def down
    drop_table :clean_modes if table_exists? :clean_modes
  end
end
