class AddAntiMessagesStatus < Jennifer::Migration::Base
  def up
    change_table(:anti_messages) do |t|
      t.add_column :status, :integer, {:null => false, :default => Policr::EnableStatus::TurnOff.value}
    end
  end

  def down
    change_table(:anti_messages) do |t|
      t.drop_column :status
    end
  end
end
