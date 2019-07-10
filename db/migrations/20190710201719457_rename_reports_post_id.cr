class RenameReportsPostId < Jennifer::Migration::Base
  def up
    change_table(:reports) do |t|
      t.change_column :post_id, :integer, {:new_name => :target_snapshot_id, :null => false, :default => 0}
    end
  end

  def down
    change_table(:reports) do |t|
      t.change_column :target_snapshot_id, :integer, {:new_name => :post_id, :null => false, :default => 0}
    end
  end
end
