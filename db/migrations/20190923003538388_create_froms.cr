class CreateFroms < Jennifer::Migration::Base
  def up
    create_table :froms do |t|
      # 群组ID
      t.integer :chat_id, {:null => false}
      # 来源列表
      t.string :list, {:null => false}
      # 是否启用
      t.bool :enabled, {:null => false}

      t.timestamps
    end
  end

  def down
    drop_table :froms if table_exists? :froms
  end
end
