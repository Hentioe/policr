class CreateMaxLengths < Jennifer::Migration::Base
  def up
    create_table :max_lengths do |t|
      # 群组ID
      t.integer :chat_id, {:null => false}
      # 总数
      t.integer :total
      # 行数
      t.integer :rows

      t.timestamps
    end
  end

  def down
    drop_table :max_lengths if table_exists? :max_lengths
  end
end
