module Policr
  class DynamicVerification < Verification
    make do
      ln = Random.rand(9) + 1
      rn = Random.rand(9) + 1
      {
        3,
        "#{ln} + #{rn} = ?",
        [
          # 注意！避免错误答案随机数重复
          # 错误答案 19 - 28
          # 错误答案 29 - 38
          # 正确答案 1 - 18
          Random.rand(19..28).to_s,
          Random.rand(29..38).to_s,
          (ln + rn).to_s,
        ],
      }
    end

    def true_index
      3
    end
  end
end
