class CreateVerificationModes < Jennifer::Migration::Base
  def up
    create_table :verification_modes do |t|
      # 群组ID
      t.integer :chat_id, {:null => false}
      # 方式
      t.integer :mode, {:null => false}
      # 倒计时（秒）
      t.integer :sec

      t.timestamps
    end
  end

  def down
    drop_table :verification_modes if table_exists? :verification_modes
  end
end
