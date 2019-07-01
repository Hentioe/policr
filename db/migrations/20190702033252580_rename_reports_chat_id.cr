class RenameReportsChatId < Jennifer::Migration::Base
  def up
    change_table(:reports) do |t|
      t.change_column :from_chat, :integer, {:new_name => :from_chat_id, :null => false, :default => 0}
    end
  end

  def down
    change_table(:reports) do |t|
      t.change_column :from_chat_id, :integer, {:new_name => :from_chat}
    end
  end
end
