class AddGroupsManaged < Jennifer::Migration::Base
  def up
    change_table(:groups) do |t|
      t.add_column :managed, :bool, {:null => false, :default => false}
    end
  end

  def down
    change_table(:groups) do |t|
      t.drop_column :managed
    end
  end
end
