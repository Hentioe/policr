class CreateGlobalRuleFlags < Jennifer::Migration::Base
  def up
    create_table :global_rule_flags do |t|
      # 群组ID
      t.integer :chat_id, {:null => false}
      # 是否启用（订阅）
      t.bool :enabled, {:null => false}
      # 是否上报
      t.bool :reported, {:null => false}
      # 执行动作
      t.integer :action, {:null => false}

      t.timestamps
    end
  end

  def down
    drop_table :global_rule_flags if table_exists? :global_rule_flags
  end
end
