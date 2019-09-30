class CreateQASuites < Jennifer::Migration::Base
  def up
    create_table :qa_suites do |t|
      # 群组ID
      t.integer :chat_id, {:null => false}
      # 标题
      t.string :title, {:null => false}
      # 答案列表
      t.string :answers, {:null => false}
      # 是否启用
      t.bool :enabled, {:null => false}

      t.timestamps
    end
  end

  def down
    drop_table :qa_suites if table_exists? :qa_suites
  end
end
