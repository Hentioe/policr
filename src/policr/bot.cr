require "telegram_bot"
require "schedule"

macro t(key, options = nil)
  I18n.translate({{key}}, {{options}})
end

module Policr
  DEFAULT_TORTURE_SEC = 55 # 默认验证等待时长（秒）

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

    def initialize(username, token, logger)
      super(username, token, logger)

      me = get_me || raise Exception.new("Failed to get bot data")
      @self_id = me["id"].as_i64

      register :join_user, JoinUserHandler
      register :join_bot, JoinBotHandler
      register :left_group, LeftGroupHandler
      register :unverified_message, UnverifiedMessageHandler
      register :from_setting, FromSettingHandler
      register :welcome_setting, WelcomeSettingHandler
      register :torture_time_setting, TortureTimeSettingHandler
      register :custom, CustomHandler
      register :halal_message, HalalMessageHandler

      register :torture, TortureCallback
      register :baned_menu, BanedMenuCallback
      register :bot_join, BotJoinCallback
      register :from, FromCallback
      register :after_event, AfterEventCallback
      register :torture_time, TortureTimeCallback
      register :custom, CustomCallback
      register :settings, SettingsCallback

      register :start, StartCommander
      register :ping, PingCommander
      register :from, FromCommander
      register :welcome, WelcomeCommander
      register :enable_examine, EnableExamineCommander
      register :disable_examine, DisableExamineCommander
      register :enable_from, EnableFromCommander
      register :disable_from, DisableFromCommander
      register :torture_time, TortureTimeCommander
      register :trust_admin, TrustAdminCommander
      register :distrust_admin, DistrustAdminCommander
      register :manageable, ManageableCommander
      register :unmanageable, UnmanageableCommander
      register :clean_mode, EnableCleanModeCommander
      register :record_mode, EnableRecordModeCommander
      register :custom, CustomCommander
      register :token, TokenCommander
      register :report, ReportCommander
      register :settings, SettingsCommander

      commanders.each do |_, command|
        cmd command.name do |msg|
          command.handle(msg)
        end
      end
    end

    def handle(msg : TelegramBot::Message)
      Cache.put_serve_group(msg.chat, self) if from_group?(msg)
      if from_group?(msg)
        DB.trust_admin(msg.chat.id) if (!DB.trust_admin?(msg.chat.id) && msg.chat.username == "translation_duang_zh_cn")
      end

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

    def display_name(user)
      name = user.first_name
      last_name = user.last_name
      name = last_name ? "#{name} #{last_name}" : name
      name
    end

    def log(text)
      logger.info text
    end

    def token
      @token
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
