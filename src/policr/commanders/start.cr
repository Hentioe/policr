module Policr
  class StartCommander < Commander
    match :start

    def handle(msg)
      text = t "start"
      bot.send_message msg.chat.id, text
    end
  end
end
