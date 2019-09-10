class CreateManagedGroups < Jennifer::Migration::Base
  def up
    create_table :managed_groups do |t|
      # 名称
      t.string :name, {:null => false}
      # 链接
      t.string :link, {:null => false}

      t.timestamps
    end
  end

  def down
    drop_table :managed_groups if table_exists? :managed_groups
  end
end
