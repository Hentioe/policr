require "telegram_bot"
require "schedule"

macro t(key, options = nil)
  I18n.translate({{key}}, {{options}})
end

module Policr
  DEFAULT_TORTURE_SEC = 45 # 默认验证等待时长（秒）

  alias Button = TelegramBot::InlineKeyboardButton
  alias Markup = TelegramBot::InlineKeyboardMarkup

  class Bot < TelegramBot::Bot
    private def register(name : Symbol, filter_type)
      filter = filter_type.new self
      case filter
      when Handler
        handlers[name] = filter
      when Callback
        callbacks[name] = filter
      when Commander
        commanders[name] = filter
      else
        raise "type '#{filter}' that does not support registration"
      end
    end

    include TelegramBot::CmdHandler

    getter self_id : Int64
    getter handlers = Hash(Symbol, Handler).new
    getter callbacks = Hash(Symbol, Callback).new
    getter commanders = Hash(Symbol, Commander).new

    def initialize
      super(Policr.username, Policr.token)

      me = get_me || raise Exception.new("Failed to get bot data")
      @self_id = me["id"].as_i64

      register :join_user, JoinUserHandler
      register :join_bot, JoinBotHandler
      register :unverified_message, UnverifiedMessageHandler
      register :halal_message, HalalMessageHandler
      register :from_setting, FromSettingHandler
      register :verify_time_setting, VerifyTimeSettingHandler
      register :custom, CustomHandler

      register :torture, TortureCallback
      register :baned_menu, BanedMenuCallback
      register :bot_join, BotJoinCallback
      register :from, FromCallback

      register :start, StartCommander
      register :ping, PingCommander
      register :from, FromCommander
      register :enable_examine, EnableExamineCommander
      register :disable_examine, DisableExamineCommander
      register :enable_from, EnableFromCommander
      register :disable_from, DisableFromCommander
      register :torture_sec, TortureSecCommander
      register :torture_min, TortureMinCommander
      register :trust_admin, TrustAdminCommander
      register :distrust_admin, DistrustAdminCommander
      register :token, TokenCommander
      register :clean_mode, EnableCleanModeCommander
      register :record_mode, EnableRecordModeCommander
      register :custom, CustomCommander

      commanders.each do |_, command|
        cmd command.name do |msg|
          command.handle(msg)
        end
      end
    end

    def handle(msg : TelegramBot::Message)
      handlers.each do |_, handler|
        handler.registry(msg)
      end

      super
    end

    def handle(query : TelegramBot::CallbackQuery)
      _handle = ->(data : String, message : TelegramBot::Message) {
        report = data.split(":")
        if report.size < 4
          logger.info "'#{get_fullname(query.from)}' clicked on the invalid inline keyboard button"
          answer_callback_query(query.id, text: "( ×ω× ) 这副内联键盘已经失效了哦", show_alert: true)
          return
        end

        call_name, _, _, _ = report

        callbacks.each do |_, callback|
          callback.handle(query, message, report[1..]) if callback.match?(call_name)
        end
      }
      if (data = query.data) && (message = query.message)
        _handle.call(data, message)
      end
    end

    def is_admin(chat_id, user_id)
      has_permission?(chat_id, user_id, :admin)
    end

    def has_permission?(chat_id, user_id, role)
      user = get_chat_member(chat_id, user_id)
      is_creator = user.status == "creator"
      case role
      when :creator
        is_creator
      when :admin
        is_creator || user.status == "administrator"
      else
        false
      end
    end

    def get_fullname(member)
      first_name = member.first_name
      last_name = member.last_name ? " #{member.last_name}" : ""
      "#{first_name}#{last_name}"
    end

    def log(text)
      logger.info text
    end

    def get_error_code_with_reason(ex : TelegramBot::APIException)
      code = -1
      reason = "Unknown"

      if data = ex.data
        reason = data["description"] || reason
        code = data["error_code"]? || code
      end
      {code, reason}
    end
  end
end
