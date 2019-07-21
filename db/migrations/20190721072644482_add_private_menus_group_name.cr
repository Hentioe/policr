class AddPrivateMenusGroupName < Jennifer::Migration::Base
  def up
    change_table(:private_menus) do |t|
      t.add_column :group_name, :string
    end
  end

  def down
    change_table(:private_menus) do |t|
      t.drop_column :group_name
    end
  end
end
