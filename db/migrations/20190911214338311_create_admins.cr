class CreateAdmins < Jennifer::Migration::Base
  def up
    create_table :admins do |t|
      # 用户ID
      t.integer :user_id, {:null => false}
      # 用户全名
      t.string :fullname

      t.timestamps
    end
  end

  def down
    drop_table :admins if table_exists? :admins
  end
end
