module Policr
  class CustomCaptcha < Captcha
    @content : Tuple(Int32, String, Array(String))?

    make ->{
      @content = DB.custom(@chat_id)
      @content || raise not_conent
    }

    def true_index
      content = @content || raise not_conent
      content.[0]
    end

    private def not_conent
      Exception.new("Group '#{@chat_id}' did not get custom CAPTCHA content")
    end
  end
end
