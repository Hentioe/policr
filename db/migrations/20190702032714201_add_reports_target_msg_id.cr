class AddReportsTargetMsgId < Jennifer::Migration::Base
  def up
    change_table(:reports) do |t|
      t.add_column :target_msg_id, :integer, {:null => false, :default => 0}
    end
  end

  def down
    change_table(:reports) do |t|
      t.drop_column :target_msg_id
    end
  end
end
