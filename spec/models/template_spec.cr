require "../spec_helper"

describe Policr::Model::Template do
  it "enable/disable/set_content!" do
    Template.enabled?(GROUP_ID).should be_falsey
    t1 = Template.set_content! GROUP_ID, "我是模板内容"
    t1.should be_truthy
    Template.enabled?(GROUP_ID).should be_falsey
    Template.enable GROUP_ID
    Template.enabled?(GROUP_ID).should be_truthy
    Template.disable GROUP_ID
    Template.enabled?(GROUP_ID).should be_falsey
    Template.delete(t1.id).should be_truthy
  end
end
