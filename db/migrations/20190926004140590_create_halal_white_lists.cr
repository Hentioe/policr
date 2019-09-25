class CreateHalalWhiteLists < Jennifer::Migration::Base
  def up
    create_table :halal_white_lists do |t|
      # 用户ID
      t.integer :user_id, {:null => false}
      # 创建人ID
      t.integer :creator_id, {:null => false}

      t.timestamps
    end
  end

  def down
    drop_table :halal_white_lists if table_exists? :halal_white_lists
  end
end
