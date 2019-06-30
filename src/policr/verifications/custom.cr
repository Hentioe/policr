module Policr
  class CustomVerification < Verification
    @content : Tuple(Int32, String, Array(String))?

    make do
      @content = KVStore.custom(@chat_id)
      @content || raise not_conent
    end

    def true_index
      content = @content || raise not_conent
      content.[0]
    end

    private def not_conent
      Exception.new("Group '#{@chat_id}' did not get custom CAPTCHA content")
    end
  end
end
