module Policr
  class DefaultVerification < Verification
    make do
      {
        1,
        t("questions.title"),
        [
          t("questions.answer_1"),
          t("questions.answer_2"),
        ],
      }
    end

    def true_index
      1
    end
  end
end
