class AddBlockContentsIsEnabled < Jennifer::Migration::Base
  def up
    change_table(:block_contents) do |t|
      t.add_column :is_enabled, :bool, {:null => false, :default => false}
    end
  end

  def down
    change_table(:block_contents) do |t|
      t.drop_column :is_enabled
    end
  end
end
