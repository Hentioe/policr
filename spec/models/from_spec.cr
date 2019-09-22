require "../spec_helper"

describe Policr::Model::From do
  it "set_list_content!/enabled?/enable!/disable" do
    f1 = From.set_list_content!(GROUP_ID, "-来源1 -来源2")
    f1.should be_truthy
    f2 = From.set_list_content!(GROUP_ID, "-来源1")
    f2.should be_truthy
    f1.id.should eq(f2.id)
    if f = From.find_by_chat_id GROUP_ID
      f.list.should eq(f2.list)
    end
    From.enabled?(GROUP_ID).should be_falsey
    From.enable! GROUP_ID
    From.enabled?(GROUP_ID).should be_truthy
    From.disable GROUP_ID
    From.enabled?(GROUP_ID).should be_falsey

    From.delete(f1.id)
  end
end
