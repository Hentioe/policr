require "../spec_helper"

describe Policr::Model::AntiMessage do
  it "enable/disable" do
    AntiMessage.enable!(GROUP_ID, ServiceMessage::JoinGroup)
    AntiMessage.enabled?(GROUP_ID, ServiceMessage::JoinGroup).should be_true
    AntiMessage.disabled?(GROUP_ID, ServiceMessage::LeaveGroup).should be_false
    AntiMessage.disable!(GROUP_ID, ServiceMessage::LeaveGroup)
    AntiMessage.disabled?(GROUP_ID, ServiceMessage::LeaveGroup).should be_true

    r = AntiMessage.where { _chat_id == GROUP_ID }.delete
    r.should be_truthy
    if r
      r.rows_affected.should eq(2)
    end
  end
end
