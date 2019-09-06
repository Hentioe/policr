module Policr
  class FromUser
    getter user_id : Int32
    getter fullname : String

    def initialize(user : TelegramBot::User?)
      if user
        @user_id = user.id
        @fullname = fullname(user)
      else
        @user_id = -1
        @fullname = "Unknown"
      end
    end

    def markdown_link(pronoun = @fullname)
      "[#{pronoun.gsub({'[' => "", ']' => ""})}](tg://user?id=#{@user_id})"
    end
  end
end
