class AddReportsPostId < Jennifer::Migration::Base
  def up
    change_table(:reports) do |t|
      t.add_column :post_id, :integer, {:null => false, :default => 0}
    end
  end

  def down
    change_table(:reports) do |t|
      t.drop_column :post_id
    end
  end
end
