require "../spec_helper"

alias VeriMode = Policr::VeriMode

describe Policr::Model::VerificationMode do
  it "fetch_by_chat_id/update_mode!/set_torture_sec!/get_torture_sec" do
    v1 = VerificationMode.fetch_by_chat_id GROUP_ID
    v1.should be_truthy

    v1.mode.should eq(VeriMode::Default.value)
    VerificationMode.update_mode!(GROUP_ID, VeriMode::Image)
    v1.reload
    v1.mode.should eq(VeriMode::Image.value)

    VerificationMode.get_torture_sec(GROUP_ID, 99).should eq(99)
    VerificationMode.set_torture_sec! GROUP_ID, 100
    VerificationMode.get_torture_sec(GROUP_ID, 99).should eq(100)

    VerificationMode.delete v1.id
  end
end
