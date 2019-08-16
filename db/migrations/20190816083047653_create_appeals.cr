class CreateAppeals < Jennifer::Migration::Base
  def up
    create_table :appeals do |t|
      # 发起人
      t.integer :author_id, {:null => false}
      t.bool :done, {:null => false}
      # 引用举报
      t.reference :report

      t.timestamps
    end
  end

  def down
    drop_foreign_key :appeals, :reports
    drop_table :appeals if table_exists? :appeals
  end
end
