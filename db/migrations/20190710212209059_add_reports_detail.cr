class AddReportsDetail < Jennifer::Migration::Base
  def up
    change_table(:reports) do |t|
      t.add_column :detail, :string
    end
  end

  def down
    change_table(:reports) do |t|
      t.drop_column :detail
    end
  end
end
