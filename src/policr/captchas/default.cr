module Policr
  class DefaultCaptcha < Captcha
    make ->{
      {
        1,
        t("questions.title"),
        [
          t("questions.answer_1"),
          t("questions.answer_2"),
        ],
      }
    }

    def true_index
      1
    end
  end
end
