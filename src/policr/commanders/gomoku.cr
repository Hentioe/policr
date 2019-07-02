require "gomoku"

module Policr
  class GomokuCommander < Commander
    alias CellColor = Gomoku::CellColor

    def initialize(bot)
      super(bot, "gomoku")
    end

    def handle(msg)
      text = t "gomoku.start"
      bot.send_message(
        msg.chat.id,
        text,
        reply_to_message_id: msg.message_id,
        disable_web_page_preview: true,
        parse_mode: "markdown",
        reply_markup: create_markup
      )
    end

    def create_markup
      markup = Markup.new

      gomoku = Gomoku::Builder.new(6).make
      gomoku.board.each_with_index do |row, y|
        btn_row = row.map_with_index do |cell, x|
          sym =
            case cell
            when CellColor::White
              "○"
            when CellColor::Black
              "●"
            else
              " "
            end
          Button.new(text: sym, callback_data: "Gomoku:#{y}#{x}")
        end
        markup << btn_row
      end

      markup
    end
  end
end
