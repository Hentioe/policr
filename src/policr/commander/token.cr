module Policr
  class TokenCommander < Commander
    def initialize(bot)
      super(bot, "token")
    end

    def handle(msg)
      case msg.chat.type
      when "supergroup" # 生成令牌
        nil
      when "private" # 获取令牌列表
        nil
      end
    end
  end
end
