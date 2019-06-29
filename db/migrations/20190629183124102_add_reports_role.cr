class AddReportsRole < Jennifer::Migration::Base
  def up
    change_table(:reports) do |t|
      t.add_column :role, :integer, {:null => false, :default => 0}
    end
  end

  def down
    change_table(:reports) do |t|
      t.drop_column :role
    end
  end
end
