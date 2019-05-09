module Policr
  class HalalMessageHandler < Handler
    ARABIC_CHARACTERS = /^[\x{0600}-\x{06FF}-\x{0750}-\x{077F}-\x{08A0}-\x{08FF}-\x{FB50}-\x{FDFF}-\x{FE70}-\x{FEFF}-\x{10E60}-\x{10E7F}-\x{1EC70}-\x{1ECBF}-\x{1ED00}-\x{1ED4F}-\x{1EE00}-\x{1EEFF} ]+$/
    SAFE_MSG_SIZE     = 2 # 消息的安全长度

    def match(msg)
      all_pass? [
        DB.enable_examine?(msg.chat.id),
        (text = msg.text),
        (user = msg.from),
        text.size > SAFE_MSG_SIZE, # 大于安全长度
        text =~ ARABIC_CHARACTERS, # 全文匹配阿拉伯字符
      ]
    end

    def handle(msg)
      if (user = msg.from) && (join_user_handler = bot.handlers[:join_user]?) && join_user_handler.is_a?(JoinUserHandler)
        join_user_handler.kick_halal_with_receipt(msg, user)
      end
    end
  end
end
