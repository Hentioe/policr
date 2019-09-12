require "../spec_helper"

describe Policr::Model::Toggle do
  it "enable/disable" do
    Toggle.enabled?(GROUP_ID, ToggleTarget::SlientMode).should be_false
    Toggle.disabled?(GROUP_ID, ToggleTarget::SlientMode).should be_false
    t1 = Toggle.enable! GROUP_ID, ToggleTarget::SlientMode
    Toggle.enabled?(GROUP_ID, ToggleTarget::SlientMode).should be_true
    Toggle.disabled?(GROUP_ID, ToggleTarget::SlientMode).should be_false
    Toggle.disable! GROUP_ID, ToggleTarget::SlientMode
    Toggle.enabled?(GROUP_ID, ToggleTarget::SlientMode).should be_false
    Toggle.disabled?(GROUP_ID, ToggleTarget::SlientMode).should be_true
    Toggle.delete(t1.id).should be_truthy
  end
end
