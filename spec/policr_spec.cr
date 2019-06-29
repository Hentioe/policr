require "./spec_helper"

alias Model = Policr::Model
alias Reason = Policr::ReportReason
alias ReportStatus = Policr::ReportStatus

describe Policr do
  it "arabic characters match" do
    arabic_characters = /^[\x{0600}-\x{06ff}-\x{0750}-\x{077f}-\x{08A0}-\x{08ff}-\x{fb50}-\x{fdff}-\x{fe70}-\x{feff} ]+$/
    r = "گچپژیلفقهمو" =~ arabic_characters
    false.should eq(r.is_a?(Nil))
  end

  it "arabic characters count" do
    arabic_characters = /[\x{0600}-\x{06ff}-\x{0750}-\x{077f}-\x{08A0}-\x{08ff}-\x{fb50}-\x{fdff}-\x{fe70}-\x{feff}]/
    i = 0
    "العَرَبِيَّة".gsub(arabic_characters) do |_|
      i += 1
    end
    12.should eq i
  end

  it "scan" do
    Policr.scan "."
  end

  it "crud" do
    author_id = 123456789.to_i64
    post_id = 33
    target_id = 987654321.to_i64
    reason = Reason::Spam.value
    status = ReportStatus::Begin.value

    r1 = Model::Report.create({author_id: author_id, post_id: post_id, target_id: target_id, reason: reason, status: status})
    r1.should be_truthy

    r2 = Model::Report.delete(r1.id)
    r2.should be_truthy
    if r2
      r2.rows_affected.should eq(1)
    end
  end
end
