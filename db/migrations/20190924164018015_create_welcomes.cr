class CreateWelcomes < Jennifer::Migration::Base
  def up
    create_table :welcomes do |t|
      # 群组ID
      t.integer :chat_id, {:null => false}
      # 欢迎内容
      t.string :content, {:null => false}
      # 是否启用
      t.bool :enabled, {:null => false}
      # 是否启用链接预览
      t.bool :link_preview_enabled, {:null => false}
      # 是否贴纸模式
      t.bool :is_sticker_mode, {:null => false}
      # 贴纸文件ID
      t.string :sticker_file_id

      t.timestamps
    end
  end

  def down
    drop_table :welcomes if table_exists? :welcomes
  end
end
