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

    include TelegramBot::CmdHandler

    getter self_id : Int64
    getter handlers = Hash(String, Handler).new
    getter callbacks = Hash(String, Callback).new
    getter commanders = Hash(String, Commander).new

    def initialize(username, token, logger)
      super(username, token, logger: logger)

      me = get_me || raise Exception.new("Failed to get bot data")
      @self_id = me["id"].as_i64

      midreg UserJoinHandler
      midreg BotJoinHandler
      midreg SelfJoinHandler
      midreg LeftGroupHandler
      midreg UnverifiedMessageHandler
      midreg FromSettingHandler
      midreg WelcomeSettingHandler
      midreg TortureTimeSettingHandler
      midreg CustomHandler
      midreg HalalMessageHandler

      midreg TortureCallback
      midreg BanedMenuCallback
      midreg BotJoinCallback
      midreg SelfJoinCallback
      midreg FromCallback
      midreg AfterEventCallback
      midreg TortureTimeCallback
      midreg CustomCallback
      midreg SettingsCallback

      midreg StartCommander
      midreg PingCommander
      midreg FromCommander
      midreg WelcomeCommander
      midreg EnableExamineCommander
      midreg DisableExamineCommander
      midreg EnableFromCommander
      midreg DisableFromCommander
      midreg TortureTimeCommander
      midreg TrustAdminCommander
      midreg DistrustAdminCommander
      midreg ManageableCommander
      midreg UnmanageableCommander
      midreg EnableCleanModeCommander
      midreg EnableRecordModeCommander
      midreg CustomCommander
      midreg TokenCommander
      midreg ReportCommander
      midreg SettingsCommander

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
