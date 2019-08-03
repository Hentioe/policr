class CreateFormatLimits < Jennifer::Migration::Base
  def up
    create_table :format_limits do |t|
      # 群组ID
      t.integer :chat_id, {:null => false}
      # 格式列表
      t.string :list, {:null => false}

      t.timestamps
    end
  end

  def down
    drop_table :format_limits if table_exists? :format_limits
  end
end
