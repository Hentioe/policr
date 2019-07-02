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
end
