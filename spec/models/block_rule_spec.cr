require "../spec_helper"

describe Policr::Model::BlockRule do
  it "enabled?/disable_all/update!/add!/load_list/load_enabled_list" do
    b1 = BlockRule.add! GROUP_ID, "[规则1]", "别名1"
    b2 = BlockRule.add! GROUP_ID, "[规则2]", "别名2"

    BlockRule.enabled?(GROUP_ID).should be_falsey

    BlockRule.load_list(GROUP_ID).size.should eq(2)
    BlockRule.load_enabled_list(GROUP_ID).size.should eq(0)

    b1.update_column :is_enabled, true
    b1.update_column :is_enabled, true

    BlockRule.enabled?(GROUP_ID).should be_truthy

    BlockRule.disable_all(GROUP_ID).should be_truthy

    BlockRule.update! b1.id.not_nil!, "[规则1.1]", "别名1"

    b1.reload

    b1.expression.should eq("[规则1.1]")

    BlockRule.delete b1.id
    BlockRule.delete b2.id
  end
end
