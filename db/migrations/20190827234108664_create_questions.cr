class CreateQuestions < Jennifer::Migration::Base
  def up
    create_table :questions do |t|
      # 群组ID
      t.integer :chat_id, {:null => false}
      # 标题
      t.string :title, {:null => false}
      # 描述
      t.string :desc
      # 注解
      t.string :note
      # 用途
      t.integer :use_for, {:null => false}
      # 是否启用
      t.bool :enabled, {:null => false}

      t.timestamps
    end
  end

  def down
    drop_table :questions if table_exists? :questions
  end
end
