require "../spec_helper"

describe Policr::Model::Question do
  it "curd" do
    # 问题/答案
    q1 = Question.create!({
      chat_id: GROUP_ID,
      title:   "我是一个问题",
      desc:    "我是问题描述",
      note:    "我是答案注解",
      use_for: QueUseFor::VotingApplyQuiz.value,
      enabled: true,
    })
    q1.should be_truthy
    q2 = Question.create!({
      chat_id: GROUP_ID,
      title:   "我是一个没启用的问题",
      desc:    "我是问题描述",
      note:    "我是答案注解",
      use_for: QueUseFor::VotingApplyQuiz.value,
      enabled: false,
    })
    q2.should be_truthy
    Question.all_voting_apply.size.should eq(2)
    Question.enabled_voting_apply.size.should eq(1)
    q1.add_answers({:name => "正确答案", :corrected => true})
    q1.add_answers({:name => "错误答案", :corrected => false})
    qq = Question.where {
      (_use_for == QueUseFor::VotingApplyQuiz.value) & (_enabled == true)
    }.first
    qq.should be_truthy
    if qq && (answers = qq.answers)
      answers = qq.answers
      answers.size.should eq(2)
      answers.each do |a|
        Answer.delete(a.id).should be_truthy
      end
    end
    Question.delete(q1.id).should be_truthy
    Question.delete(q2.id).should be_truthy
  end
end
