class CreateTemplates < Jennifer::Migration::Base
  def up
    create_table :templates do |t|
      # 群组ID
      t.integer :chat_id, {:null => false}
      # 模板内容
      t.string :content, {:null => false}
      # 是否启用
      t.bool :enabled, {:null => false}

      t.timestamps
    end
  end

  def down
    drop_table :templates if table_exists? :templates
  end
end
