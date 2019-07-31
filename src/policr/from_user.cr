module Policr
  class FromUser
    getter user : TelegramBot::User?

    def initialize(@user)
    end

    def markdown_link
      if user = @user
        "[#{Policr.display_name(user)}](tg://user?id=#{user.id})"
      else
        "Unknown"
      end
    end
  end
end
