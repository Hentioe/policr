require "../spec_helper"

describe Policr::Model::BlockRule do
  it "enabled?/disable/enable!/update!/add!/list/apply/disapply" do
    b1 = BlockRule.add! GROUP_ID, "[规则1]", "别名1"
    b2 = BlockRule.add! GROUP_ID, "[规则2]", "别名2"

    BlockRule.enabled?(GROUP_ID).should be_falsey

    BlockRule.all_list(GROUP_ID).size.should eq(2)
    BlockRule.apply_message_list(GROUP_ID).size.should eq(0)

    BlockRule.enable!(b1.id)
    BlockRule.enable!(b2.id)
    BlockRule.apply_nickname!(b1.id)

    BlockRule.apply_message_list(GROUP_ID).size.should eq(2)
    BlockRule.apply_nickname_list(GROUP_ID).size.should eq(1)

    BlockRule.disapply_message(b1.id)
    BlockRule.apply_message_list(GROUP_ID).size.should eq(1)

    BlockRule.enabled?(GROUP_ID).should be_truthy

    BlockRule.disable_all(GROUP_ID).should be_truthy

    BlockRule.update! b1.id, "[规则1.1]", "别名1"

    b1.reload

    b1.expression.should eq("[规则1.1]")

    BlockRule.delete b1.id
    BlockRule.delete b2.id
  end
end
