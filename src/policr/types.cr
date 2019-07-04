module Policr
  enum TortureTimeType
    Sec; Min
  end

  enum ReportReason
    Unknown; Spam; Halal
  end

  enum ReportStatus
    Unknown; Begin; Reject; Accept; Unban
  end

  enum ReportUserRole
    Unknown; Creator; Admin; TrustedAdmin; Member
  end

  enum VoteType
    Agree; Abstention; Oppose
  end

  # 启用状态
  enum EnableStatus
    Unknown; TurnOn; TurnOff
  end

  # 干净模式删除目标
  enum CleanDeleteTarget
    Unknown; TimeoutVerified; WrongVerified; Welcome; From
  end

  enum TimeUnit
    Sec; Min; Hour
  end

  class FromUser
    getter user : TelegramBot::User?

    def initialize(@user)
    end

    def markdown_link
      if user = @user
        "[#{Policr.display_name(user)}](tg://user?id=#{user.id})"
      else
        "Unknown"
      end
    end
  end

  enum QuestionType
    Normal; Image
  end

  class Question
    getter type : QuestionType
    getter true_index : Int32
    getter title : String
    getter answers : Array(Array(String))
    getter file_path : String?
    getter discord : Bool = false

    def initialize(@type, @true_index, @title, @answers, @file_path = nil)
    end

    def self.normal_build(true_index, title, answers)
      Question.new(QuestionType::Normal, true_index, title, answers)
    end

    def self.image_build(true_index, title, answers, file_path)
      Question.new(QuestionType::Image, true_index, title, answers, file_path)
    end

    def discord
      @discord = true
      self
    end
  end
end
