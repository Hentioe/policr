require "../spec_helper"

alias HitAction = Policr::HitAction

describe Policr::Model::GlobalRuleFlag do
  it "fetch_id!/enable!/enabled?/disable/enable_report!/disable_report/switch_action!" do
    f1 = GlobalRuleFlag.fetch_by_chat_id! GROUP_ID
    f1.should be_truthy

    GlobalRuleFlag.enabled?(GROUP_ID).should be_falsey
    GlobalRuleFlag.enable!(GROUP_ID).should be_truthy
    GlobalRuleFlag.enabled?(GROUP_ID).should be_truthy

    GlobalRuleFlag.disable(GROUP_ID)
    GlobalRuleFlag.enabled?(GROUP_ID).should be_falsey

    GlobalRuleFlag.enable!(GROUP_ID).should be_truthy
    GlobalRuleFlag.enable_report! GROUP_ID
    f1.reload
    f1.reported.should be_true

    GlobalRuleFlag.disable_report GROUP_ID
    f1.reload
    f1.reported.should be_false

    f1.action.should eq(HitAction::Restrict.value)
    GlobalRuleFlag.switch_action! GROUP_ID, HitAction::Delete
    f1.reload
    f1.action.should eq(HitAction::Delete.value)

    GlobalRuleFlag.delete f1.id
  end
end
