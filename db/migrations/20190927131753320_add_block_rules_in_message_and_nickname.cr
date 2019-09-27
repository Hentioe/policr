class AddBlockRulesInMessageAndNickname < Jennifer::Migration::Base
  def up
    change_table(:block_rules) do |t|
      t.add_column :in_message, :bool, {:null => false, :default => true}
      t.add_column :in_nickname, :bool, {:null => false, :default => false}
    end
  end

  def down
    change_table(:block_rules) do |t|
      t.drop_column :in_message
      t.drop_column :in_nickname
    end
  end
end
