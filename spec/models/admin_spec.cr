require "../spec_helper"

describe Policr::Model::Admin do
  it "manage groups" do
    a1 = Admin.create!({user_id: USER_ID})
    a1.should be_truthy
    a1.add_groups({:chat_id => GROUP_ID, :title => GROUP_TITLE_1})

    g1 = Group.where { _chat_id == GROUP_ID }.first
    g1.should be_truthy

    if a1 && g1
      Admin.delete(a1.id).should be_truthy
      Group.delete(g1.id).should be_truthy
    end
  end
end
