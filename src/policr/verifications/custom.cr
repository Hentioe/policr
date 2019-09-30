module Policr
  class CustomVerification < Verification
    @indeces = Array(Int32).new

    make do
      suite = Model::QASuite.find_by_chat_id(@chat_id) || raise not_conent
      @indeces, answers = suite.gen_answers
      answers = answers.map { |answer| [answer] }
      Question.normal_build(suite.title, answers).discord
    end

    def indeces
      @indeces
    end

    private def not_conent
      Exception.new("Group '#{@chat_id}' did not get custom CAPTCHA content")
    end
  end
end
