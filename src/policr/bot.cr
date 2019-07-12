require "telegram_bot"
require "schedule"

macro t(key, options = nil)
  I18n.translate({{key}}, {{options}})
end

macro is_private_chat?(chat_id)
  {{chat_id}} > 0
end

module Policr
  DEFAULT_TORTURE_SEC = 55 # 默认验证等待时长（秒）

  alias Button = TelegramBot::InlineKeyboardButton
  alias Markup = TelegramBot::InlineKeyboardMarkup

  def self.display_name(user)
    name = user.first_name
    last_name = user.last_name
    name = last_name ? "#{name} #{last_name}" : name
    name
  end

  class Bot < TelegramBot::Bot
    private macro midreg(cls)
      {{ cls_name = cls.stringify }}
      {{ key = cls_name.underscore.gsub(/(_handler|_commander|_callback)/, "") }}
      %mid =
      {% if cls_name.ends_with?("Handler") %}
        handlers
      {% elsif cls_name.ends_with?("Commander") %}
        commanders
      {% elsif cls_name.ends_with?("Callback") %}
        callbacks
      {% end %}
      %mid[{{key}}] = {{cls}}.new self
    end

    private macro regall(cls_list)
      {% for cls in cls_list %}
        midreg {{cls}}
      {% end %}
    end

    include TelegramBot::CmdHandler

    getter self_id : Int64
    getter handlers = Hash(String, Handler).new
    getter callbacks = Hash(String, Callback).new
    getter commanders = Hash(String, Commander).new

    getter snapshot_channel : String
    getter voting_channel : String
    getter username : String

    def initialize(username, token, logger, snapshot_channel, voting_channel)
      super(username, token, logger: logger)
      @snapshot_channel = snapshot_channel
      @voting_channel = voting_channel
      @username = username

      me = get_me || raise Exception.new("Failed to get bot data")
      @self_id = me["id"].as_i64

      # 注册消息处理模块
      regall [
        UserJoinHandler,
        BotJoinHandler,
        SelfJoinHandler,
        LeftGroupHandler,
        UnverifiedMessageHandler,
        FromSettingHandler,
        WelcomeSettingHandler,
        TortureTimeSettingHandler,
        CustomHandler,
        HalalMessageHandler,
        PrivateForwardHandler,
        ReportDetailHandler,
      ]

      # 注册回调模块
      regall [
        TortureCallback,
        BanedMenuCallback,
        BotJoinCallback,
        SelfJoinCallback,
        FromCallback,
        AfterEventCallback,
        TortureTimeCallback,
        CustomCallback,
        SettingsCallback,
        ReportCallback,
        VotingCallback,
        CleanModeCallback,
        DelayTimeCallback,
        SubfunctionsCallback,
        PrivateForwardCallback,
        PrivateForwardReportCallback,
      ]

      # 注册指令模块
      regall [
        StartCommander,
        PingCommander,
        FromCommander,
        WelcomeCommander,
        TortureTimeCommander,
        CustomCommander,
        TokenCommander,
        ReportCommander,
        SettingsCommander,
        StepCommander,
        CleanModeCommander,
        GomokuCommander,
        SubfunctionsCommander,
        StrictModeCommander,
      ]

      commanders.each do |_, command|
        cmd command.name do |msg|
          command.handle(msg)
        end
      end
    end

    def handle(msg : TelegramBot::Message)
      Cache.put_serve_group(msg.chat, self) if from_group?(msg)

      super

      handlers.each do |_, handler|
        handler.registry(msg)
      end
    end

    def handle_edited(msg : TelegramBot::Message)
      handlers.each do |_, handler|
        handler.registry(msg, from_edit: true)
      end
    end

    def handle(query : TelegramBot::CallbackQuery)
      _handle = ->(data : String, message : TelegramBot::Message) {
        report = data.split(":")
        if report.size < 2
          logger.info "'#{display_name(query.from)}' clicked on the invalid inline keyboard button"
          answer_callback_query(query.id, text: t("invalid_callback"))
          return
        end

        call_name = report[0]

        callbacks.each do |_, callback|
          callback.handle(query, message, report[1..]) if callback.match?(call_name)
        end
      }
      if (data = query.data) && (message = query.message)
        _handle.call(data, message)
      end
    end

    def is_admin?(chat_id, user_id)
      has_permission?(chat_id, user_id, :admin)
    end

    def has_permission?(chat_id, user_id, role, dirty = true)
      return false if is_private_chat?(chat_id) # 私聊无权限
      if admins = Cache.get_admins chat_id      # 从缓存中获取管理员列表
        tmp_filter_users = admins.select { |m| m.user.id == user_id }
        noperm = tmp_filter_users.size == 0
        status = noperm ? nil : tmp_filter_users[0].status

        is_creator = status == "creator"
        result =
          !noperm &&
            case role
            when :creator
              is_creator
            when :admin
              is_creator || status == "administrator"
            else
              false
            end

        # 异步更新缓存
        spawn { Cache.set_admins chat_id, get_chat_administrators(chat_id) } if dirty
        result
      else # 没有获得管理员列表，缓存并递归
        Cache.set_admins chat_id, get_chat_administrators(chat_id)
        has_permission?(chat_id, user_id, role, dirty: false)
      end
    end

    def from_group?(msg)
      case msg.chat.type
      when "supergroup"
        true
      when "group"
        true
      else
        false
      end
    end

    def from_supergroup?(msg)
      msg.chat.type == "supergroup"
    end

    def log(text)
      logger.info text
    end

    def token
      @token
    end

    def display_name(user)
      Policr.display_name user
    end

    def parse_error(ex : TelegramBot::APIException)
      code = -1
      reason = "Unknown"

      if data = ex.data
        reason = data["description"] || reason
        code = data["error_code"]? || code
      end
      {code, reason.to_s}
    end
  end
end
