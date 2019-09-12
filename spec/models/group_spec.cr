require "../spec_helper"

describe Policr::Model::Group do
  it "manage admins" do
    g1 = Group.create!({chat_id: GROUP_ID, title: GROUP_TITLE_1})
    g1.should be_truthy
    g1.add_admins({:user_id => USER_ID, :is_owner => false})

    a1 = Admin.where { _user_id == USER_ID }.first
    a1.should be_truthy

    if g1 && a1
      Group.delete(g1.id).should be_truthy
      Admin.delete(a1.id).should be_truthy
    end
  end
end
