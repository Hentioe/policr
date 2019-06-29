# 创建举报表结构
class CreateReports < Jennifer::Migration::Base
  def up
    create_table :reports do |t|
      # 发起人
      t.integer :author_id, {:null => false}
      # 快照消息
      t.integer :post_id, {:null => false}
      # 目标用户
      t.integer :target_id, {:null => false}
      # 原因
      t.integer :reason, {:null => false}
      # 处理状态
      t.integer :status, {:null => false}

      t.timestamps
    end
  end

  def down
    drop_table :reports if table_exists? :reports
  end
end
