class CreateVotes < Jennifer::Migration::Base
  def up
    create_table :votes do |t|
      # 发起人
      t.integer :author_id, {:null => false}
      # 类型
      t.integer :type, {:null => false}
      # 权重
      t.integer :weight, {:null => false}
      # 引用举报
      t.reference :report
      t.timestamps
    end
  end

  def down
    drop_foreign_key :votes, :reports
    drop_table :votes if table_exists? :votes
  end
end
