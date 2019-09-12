class CreateAdmins < Jennifer::Migration::Base
  def up
    create_table :admins do |t|
      # 用户ID
      t.integer :user_id, {:null => false}
      # 群主？
      t.bool :is_owner, {:null => false}

      # 引用群组
      t.reference :group

      t.timestamps
    end
  end

  def down
    drop_table :admins if table_exists? :admins
  end
end
