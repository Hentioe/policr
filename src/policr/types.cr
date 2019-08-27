module Policr
  enum ToggleTarget
    SlientMode
  end

  enum VerificationStatus
    Init; Passed; Slowed; Next; Left
  end

  enum TortureTimeType
    Sec; Min
  end

  # 问题用途
  enum QueUseFor
    Unknown; Verification; VotingApplyQuiz; Appeal
  end

  enum ReportReason
    Unknown; MassAd; Halal; Other; Hateful; Adname; VirusFile; PromoFile
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
    Unknown; TimeoutVerified; WrongVerified; Welcome; From; Halal; Report
  end

  # 服务消息类型
  enum ServiceMessage
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

  class InlineLink
    @text : String
    @url : String

    def initialize(@text, @url)
    end

    def markdown
      "[#{@text}](#{@url})"
    end
  end
end
