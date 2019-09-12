require "../spec_helper"

describe Policr::Model::FormatLimit do
  it "put_list/includes?/clear/find" do
    FormatLimit.put_list!(GROUP_ID, ["mp4", "gif"])
    FormatLimit.includes?(GROUP_ID, "mp4").should be_true
    FormatLimit.clear(GROUP_ID)
    FormatLimit.includes?(GROUP_ID, "mp4").should be_false
    FormatLimit.find(GROUP_ID).should be_falsey
  end
end
