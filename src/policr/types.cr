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
end
