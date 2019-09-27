class RenameBlockRulesIsEnabled < Jennifer::Migration::Base
  def up
    change_table(:block_rules) do |t|
      t.change_column :is_enabled, :bool, {:new_name => :enabled, :null => false, :default => false}
    end
  end

  def down
    change_table(:block_rules) do |t|
      t.change_column :enabled, :bool, {:new_name => :is_enabled, :null => false, :default => false}
    end
  end
end
