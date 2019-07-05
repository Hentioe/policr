require "gomoku"

module Policr
  class GomokuVerification < Verification
    SIZE = 6
    alias CellColor = Gomoku::CellColor
    getter true_index : Int32?

    make do
      gomoku = Gomoku::Builder.new(SIZE).make
      answers = Array(Array(String)).new
      y, x = gomoku.victory_coords
      @true_index = (y * SIZE) + x + 1
      gomoku.board.each_with_index do |row, y|
        answer_line = Array(String).new
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
          answer_line.push sym
        end
        answers.push answer_line
      end

      Question.normal_build("使用五子棋规则：落一颗 ● （实心圆）子取得胜利", answers)
    end

    def true_index
      @true_index
    end
  end
end
