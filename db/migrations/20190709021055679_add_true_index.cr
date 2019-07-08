class AddTrueIndex < Jennifer::Migration::Base
  def up
    create_table :true_indices do |t|
      # 群组ID
      t.integer :chat_id, {:null => false}
      # 消息ID
      t.integer :msg_id, {:null => false}
      # 正确答案列表
      t.string :indices

      t.timestamps
    end
  end

  def down
    drop_table :true_indices if table_exists? :true_indices
  end
end
