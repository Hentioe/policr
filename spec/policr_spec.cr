require "./spec_helper"

describe Policr do
  # TODO: Write tests

  it "works" do
    true.should eq(true)
  end

  it "arabic characters match" do
    arabic_characters = /^[\x{0600}-\x{06ff}-\x{0750}-\x{077f}-\x{08A0}-\x{08ff}-\x{fb50}-\x{fdff}-\x{fe70}-\x{feff} ]+$/
    r = "گچپژیلفقهمو" =~ arabic_characters
    false.should eq(r.is_a?(Nil))
  end
end
