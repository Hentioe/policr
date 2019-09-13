require "../spec_helper"

describe Policr::Model::Group do
  it "add admins" do
    g1 = Group.create!({chat_id: GROUP_ID, title: GROUP_TITLE_1, managed: true})
    g1.should be_truthy
    g1.add_admins({:user_id => USER_ID})

    a1 = Admin.where { _user_id == USER_ID }.first
    a1.should be_truthy

    if g1 && a1
      Group.delete(g1.id).should be_truthy
      Admin.delete(a1.id).should be_truthy
    end
  end

  it "reset admins" do
    g1 = Group.create!({chat_id: GROUP_ID, title: GROUP_TITLE_1, managed: true})
    g1.should be_truthy
    a1 = g1.add_admins({:user_id => USER_ID})
    a1.should be_truthy

    a2 = Admin.fetch_by_user_id!(USER_ID_1)
    a3 = Admin.fetch_by_user_id!(USER_ID_2)

    g1.reset_admins([a2, a3])

    admins = g1.admins_reload
    admins.size.should eq(2)
    admins.select { |a| a.id == USER_ID }.size.should eq(0)

    Group.delete(GROUP_ID).should be_truthy
    Admin.delete(USER_ID).should be_truthy
    Admin.delete(USER_ID_1).should be_truthy
    Admin.delete(USER_ID_2).should be_truthy
  end
end
