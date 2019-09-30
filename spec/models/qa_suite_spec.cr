require "../spec_helper"

describe Policr::Model::QASuite do
  it "find_by_chat_id/add!/update!" do
    QASuite.find_by_chat_id(GROUP_ID).should be_falsey
    qa1 = QASuite.add! GROUP_ID, "我是标题", "+正确答案\n-错误答案"
    qa1.should be_truthy
    qa1 = qa1.not_nil!

    QASuite.update! qa1.id, "修改后的标题", "+正确答案"
    qa1.reload
    qa1.answers.should eq("+正确答案")

    QASuite.delete qa1.id
  end
end
