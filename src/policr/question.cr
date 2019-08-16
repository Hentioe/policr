module Policr
  class Question
    getter type : QuestionType
    getter title : String
    getter answers : Array(Array(String))
    getter file_path : String?
    getter is_discord : Bool = false

    def initialize(@type, @title, @answers, @file_path = nil)
    end

    def self.normal_build(title, answers)
      Question.new(QuestionType::Normal, title, answers)
    end

    def self.image_build(title, answers, file_path)
      Question.new(QuestionType::Image, title, answers, file_path)
    end

    def disorder
      @is_discord = true
      self
    end

    def discord
      disorder
    end
  end
end
