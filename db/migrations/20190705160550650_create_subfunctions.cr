class CreateSubfunctions < Jennifer::Migration::Base
  def up
    create_table :subfunctions do |t|
      # 群组ID
      t.integer :chat_id, {:null => false}
      # 功能类型
      t.integer :type, {:null => false}
      # 启用状态
      t.integer :status, {:null => false}

      t.timestamps
    end
  end

  def down
    drop_table :subfunctions if table_exists? :subfunctions
  end
end
