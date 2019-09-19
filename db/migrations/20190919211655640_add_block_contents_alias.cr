class AddBlockContentsAlias < Jennifer::Migration::Base
  def up
    change_table(:block_contents) do |t|
      t.add_column :alias_s, :bool, {:null => false, :default => "未命名"}
    end
  end

  def down
    change_table(:block_contents) do |t|
      t.drop_column :alias_s
    end
  end
end
