require "../spec_helper"

describe Policr::Model::HalalWhiteList do
  it "contains?" do
    h1 = HalalWhiteList.add!(USER_ID_1, USER_ID_2)
    h2 = HalalWhiteList.add!(USER_ID_1, USER_ID_2)

    h1.id.should eq(h2.id)

    HalalWhiteList.contains?(USER_ID_1).should be_truthy

    HalalWhiteList.delete(h1.id)
  end
end
