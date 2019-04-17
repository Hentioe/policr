module Policr
  class HalalMessageHandler < Handler
    ARABIC_CHARACTERS = /^[\x{0600}-\x{06FF}-\x{0750}-\x{077F}-\x{08A0}-\x{08FF}-\x{FB50}-\x{FDFF}-\x{FE70}-\x{FEFF}-\x{10E60}-\x{10E7F}-\x{1EC70}-\x{1ECBF}-\x{1ED00}-\x{1ED4F}-\x{1EE00}-\x{1EEFF} ]+$/

    @text : (Nil | String)
    @user : (Nil | TelegramBot::User)

    def match(msg)
      @text = msg.text
      @user = msg.from

      DB.enable_examine?(msg.chat.id) &&
        (text = @text) && @user &&
        (text.size > SAFE_MSG_SIZE && text =~ ARABIC_CHARACTERS)
    end

    def handle(msg)
      if (text = @text) && (user = @user) && (join_user_handler = bot.handlers[:join_user]?) && join_user_handler.is_a?(JoinUserHandler)
        join_user_handler.kick_halal_with_receipt(msg, user) if (text.size > SAFE_MSG_SIZE && text =~ ARABIC_CHARACTERS)
      end
    end
  end
end
