class CreateToggles < Jennifer::Migration::Base
  def up
    create_table :toggles do |t|
      # 群组ID
      t.integer :chat_id, {:null => false}
      # 作用目标
      t.integer :target, {:null => false}
      # 是否启用
      t.bool :enabled, {:null => false}

      t.timestamps
    end
  end

  def down
    drop_table :toggles if table_exists? :toggles
  end
end
