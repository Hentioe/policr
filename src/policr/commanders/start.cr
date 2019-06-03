module Policr
  class StartCommander < Commander
    def initialize(bot)
      super(bot, "start")
    end

    def handle(msg)
      text = t "start"
      bot.send_message(msg.chat.id, text, disable_web_page_preview: true, parse_mode: "markdown")
    end
  end
end
