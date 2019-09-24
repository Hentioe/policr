require "../spec_helper"

describe Policr::Model::Welcome do
  it "set_content!/enabled?/disabled?/enable!/disable" do
    w1 = Welcome.set_content! GROUP_ID, "我是欢迎消息内容"
    w2 = Welcome.set_content! GROUP_ID, "我是更新后的欢迎消息内容"

    w1.id.should eq(w2.id)
    if w = Welcome.find_by_chat_id GROUP_ID
      w.content.should eq(w2.content)
    end

    Welcome.enabled?(GROUP_ID).should be_falsey
    Welcome.enable! GROUP_ID
    Welcome.enabled?(GROUP_ID).should be_truthy

    Welcome.sticker_mode_enabled?(GROUP_ID).should be_falsey
    Welcome.enable_sticker_mode! GROUP_ID
    Welcome.sticker_mode_enabled?(GROUP_ID).should be_truthy

    Welcome.link_preview_disabled?(GROUP_ID).should be_falsey
    Welcome.disable_link_preview GROUP_ID
    Welcome.link_preview_disabled?(GROUP_ID).should be_truthy

    Welcome.delete w1.id
  end
end
