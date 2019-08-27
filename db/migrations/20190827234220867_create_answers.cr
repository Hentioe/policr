class CreateAnswers < Jennifer::Migration::Base
  def up
    create_table :answers do |t|
      # 名称
      t.string :name, {:null => false}
      # 是否正确
      t.bool :corrected, {:null => false}
      # 引用问题
      t.reference :question

      t.timestamps
    end
  end

  def down
    drop_foreign_key :answers, :questions
    drop_table :answers if table_exists? :answers
  end
end
