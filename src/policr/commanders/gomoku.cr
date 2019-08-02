require "gomoku"

module Policr
  class GomokuCommander < Commander
    alias CellColor = Gomoku::CellColor

    match :gomoku

    def handle(msg)
      text = t "gomoku.start"
      bot.send_message(
        msg.chat.id,
        text: text,
        reply_to_message_id: msg.message_id,
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
