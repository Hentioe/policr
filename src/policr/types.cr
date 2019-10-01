module Policr
  enum HitAction # 命中动作
    Delete       # 删除
    Restrict     # 禁言
    Ban          # 封禁
  end

  enum ToggleTarget # 综合设置开关
    SlientMode      # 静音模式
    ExamineEnabled  # 启用审核
    TrustedAdmin    # 信任管理
    PrivacySetting  # 隐私设置
    RecordMode      # 记录模式
    FaultTolerance  # 容错模式
  end

  enum VeriMode # 验证方式
    Default     # 默认验证
    Custom      # 自定义验证（定制验证）
    Arithmetic  # 算术验证
    Image       # 图片验证
    Chessboard  # 棋局验证
  end

  enum VerificationStatus
    Init
    Passed
    Slowed
    Next
    Left
    Wrong
  end

  enum TortureTimeType
    Sec; Min
  end

  # 问题用途
  enum QueUseFor
    Unknown; Verification; VotingApplyQuiz; Appeal
  end

  enum ReportReason
    Unknown
    MassAd
    Halal
    Other
    Hateful
    Adname
    VirusFile
    PromoFile
    Bocai
    HitGlobalRule
    HitGlobalRuleNickname
  end

  # 举报状态
  enum ReportStatus
    Unknown; Begin; Reject; Accept; Unban
  end

  enum ReportUserRole
    Unknown
    Creator
    Admin
    TrustedAdmin
    Member
    System
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
    Unknown
    JoinGroup     # 入群消息
    LeaveGroup    # 退群消息
    DataChange    # 资料变更
    PinnedMessage # 置顶消息
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
