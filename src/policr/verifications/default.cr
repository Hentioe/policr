module Policr
  class DefaultVerification < Verification
    @indeces = [1]

    make do
      title = t "questions.title"
      answers = [[t("questions.answer_1")],
                 [t("questions.answer_2")]]
      Question.normal_build(title, answers).discord
    end

    def indeces
      @indeces
    end
  end
end
