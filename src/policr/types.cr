module Policr
  enum VerificationStatus
    Init; Passed; Slowed; Next
  end

  enum TortureTimeType
    Sec; Min
  end

  enum ReportReason
    Unknown; Spam; Halal; Other; Hateful; Adname; VirusFile; PromoFile
  end

  # 举报状态
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

  # 服务消息类型
  enum AntiMessageDeleteTarget
    Unknown; JoinGroup; LeaveGroup
  end

  # 时间单位
  enum TimeUnit
    Sec; Min; Hour
  end

  # 子功能类型
  enum SubfunctionType
    Unknown; UserJoin; BotJoin; BanHalal; Blacklist
  end

  enum LanguageCode
    English; ZhHans; ZhHant
  end

  enum QuestionType
    Normal; Image
  end

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

    def discord
      @is_discord = true
      self
    end
  end
end
