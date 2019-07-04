module Policr
  class DynamicVerification < Verification
    @true_index = 6

    make do
      ln = Random.rand(1...50)
      rn = Random.rand(1...50)
      true_ans = ln + rn
      error_optional = (2..98).to_a.select { |i| i != true_ans }
      error_ans = (0..4).map { error_optional.delete_at Random.rand(0...error_optional.size) }
      title = "#{ln} + #{rn} = ?"
      answers = [error_ans.map { |i| i.to_s }.push((ln + rn).to_s)]

      Question.normal_build(@true_index, title, answers).discord
    end

    def true_index
      @true_index
    end
  end
end
