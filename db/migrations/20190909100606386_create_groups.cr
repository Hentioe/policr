class CreateGroups < Jennifer::Migration::Base
  def up
    create_table :groups do |t|
      # 群组ID
      t.integer :chat_id, {:null => false}
      # 名称
      t.string :name, {:null => false}
      # 链接
      t.string :link, {:null => false}

      t.timestamps
    end
  end

  def down
    drop_table :groups if table_exists? :groups
  end
end
