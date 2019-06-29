class AddReportsFromChat < Jennifer::Migration::Base
  def up
    change_table(:reports) do |t|
      t.add_column :from_chat, :integer
    end
  end

  def down
    change_table(:reports) do |t|
      t.drop_column :from_chat
    end
  end
end
