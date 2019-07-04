module Policr
  class CustomVerification < Verification
    @true_index : Int32?

    make do
      content = KVStore.custom(@chat_id) || raise not_conent
      @true_index, title, answers = content
      answers = answers.map { |answer| [answer] }
      Question.normal_build(title, answers).discord
    end

    def true_index
      @true_index || raise not_conent
    end

    private def not_conent
      Exception.new("Group '#{@chat_id}' did not get custom CAPTCHA content")
    end
  end
end
