module Policr
  class CustomVerification < Verification
    @indeces = Array(Int32).new

    make do
      content = KVStore.custom(@chat_id) || raise not_conent
      @indeces, title, answers = content
      answers = answers.map { |answer| [answer] }
      Question.normal_build(title, answers).discord
    end

    def indeces
      @indeces
    end

    private def not_conent
      Exception.new("Group '#{@chat_id}' did not get custom CAPTCHA content")
    end
  end
end
