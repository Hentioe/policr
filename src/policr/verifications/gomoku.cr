require "gomoku"

module Policr
  class GomokuVerification < Verification
    SIZE = 6
    alias CellColor = Gomoku::CellColor
    getter true_index : Int32?

    make do
      gomoku = Gomoku::Builder.new(SIZE).make
      gomoku.print
      answers = Array(Array(String)).new
      y, x = gomoku.victory_coords
      gomoku.print
      @true_index = (y * SIZE) + x
      puts @true_index
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

      Question.normal_build(@true_index || 0, "使用五子棋规则：让 ● 子取得胜利", answers)
    end

    def true_index
      puts @true_index
      @true_index
    end
  end
end
