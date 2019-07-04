module Policr
  class DefaultVerification < Verification
    @true_index = 1

    make do
      title = t "questions.title"
      answers = [[t("questions.answer_1")],
                 [t("questions.answer_2")]]
      Question.normal_build(@true_index, title, answers).discord
    end

    def true_index
      @true_index
    end
  end
end
