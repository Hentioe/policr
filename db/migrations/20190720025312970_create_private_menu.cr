class CreatePrivateMenu < Jennifer::Migration::Base
  def up
    create_table :private_menus do |t|
      # 私聊ID
      t.integer :chat_id, {:null => false}
      # 消息ID
      t.integer :msg_id, {:null => false}
      # 群组ID
      t.integer :group_id, {:null => false}

      t.timestamps
    end
  end

  def down
    drop_table :private_menus if table_exists? :private_menus
  end
end
