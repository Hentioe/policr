class AddReportsAppealPostId < Jennifer::Migration::Base
  def up
    change_table(:reports) do |t|
      t.add_column :appeal_post_id, :integer
    end
  end

  def down
    change_table(:reports) do |t|
      t.drop_column :appeal_post_id
    end
  end
end
