class RenameBlockContents < Jennifer::Migration::Base
  def up
    change_table :block_contents do |t|
      t.rename_table :block_rules
    end
  end

  def down
    change_table :block_rules do |t|
      t.rename_table :block_contents
    end
  end
end
