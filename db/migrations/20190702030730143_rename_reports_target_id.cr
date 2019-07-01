class RenameReportsTargetId < Jennifer::Migration::Base
  def up
    change_table(:reports) do |t|
      t.change_column :target_id, :integer, {:new_name => :target_user_id, :null => false, :default => 0}
    end
  end

  def down
    change_table(:reports) do |t|
      t.change_column :target_user_id, :integer, {:new_name => :target_id, :null => false, :default => 0}
    end
  end
end
