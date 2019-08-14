require "telegram_bot"
require "schedule"

macro t(key, options = nil, locale = "zh-hans")
  I18n.translate({{key}}, {{options}}, {{locale}})
end

def escape_markdown(text)
  if text
    escape_all text, "\\\\", ["*", "_", "`"]
  end
end

macro def_text(method_name = "create_text", *args)
  {{ args_exp_s = args.join(", ") }}

  def {{method_name.id}}(_group_id, {{args_exp_s.id}}{% if args.size > 0 %},{% end %} group_name : String? = nil)
    %text = {{yield}}
    wrapper_title %text
  end
end

macro def_markup(method_name = "create_markup", *args)
  {{ args_exp_s = args.join(", ") }}

  def {{method_name.id}}(_group_id, {{args_exp_s.id}}{% if args.size > 0 %},{% end %} group_name : String? = nil)
    _markup = Markup.new

    {{yield}}

    _markup
  end
end

macro render(str, vars, vals)
  {{str}}.
  {% for var, i in vars %}
    gsub(/\\{\\{\s?{{var.id}}\s?\}\}/, {{vals}}[{{i}}])
      {% if i < vars.size - 1 %}.{% end %}
  {% end %}
end

def from_group_chat?(msg)
  case msg.chat.type
  when "supergroup"
    true
  when "group"
    true
  else
    false
  end
end

def from_private_chat?(msg)
  !from_group_chat?(msg)
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
    private macro regall(cls_list)
      {% for cls in cls_list %}
        midreg {{cls}}
      {% end %}
    end

    alias AntiTarget = AntiMessageDeleteTarget

    include TelegramBot::CmdHandler

    getter self_id : Int64
    getter handlers = Hash(String, Handler).new
    getter callbacks = Hash(String, Callback).new
    getter commanders = Hash(String, Commander).new
    getter command_names = Set(String).new

    getter snapshot_channel : String
    getter voting_channel : String
    getter username : String
    getter owner_id : String

    def initialize(username, token, @owner_id, logger, @snapshot_channel, @voting_channel)
      super(username, token, logger: logger)
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
        BlockedContentHandler,
        MaxLengthHandler,
        MaxLengthSettingHandler,
        CleanModeTimeSettingHandler,
        FormatLimitHandler,
        FormatLimitSettingHandler,
        PrivateChatReplyHandler,
        PrivateChatHandler,
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
        StrictModeCallback,
        MaxLengthCallback,
        WelcomeCallback,
        LanguageCallback,
        AntiServiceMsgCallback,
        FormatLimitCallback,
        FromSettingCallback,
        AppealCallback,
      ]

      # 注册指令模块
      regall [
        StartCommander,
        PingCommander,
        FromCommander,
        WelcomeCommander,
        TortureTimeCommander,
        CustomCommander,
        ReportCommander,
        SettingsCommander,
        CleanModeCommander,
        SubfunctionsCommander,
        StrictModeCommander,
        LanguageCommander,
        AntiServiceMsgCommander,
        TemplateCommander,
        AppealCommander,
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

      state = Hash(Symbol, StateValueType).new
      handlers.each do |_, handler|
        handler.registry(msg, state)
      end
    end

    def handle_edited(msg : TelegramBot::Message)
      state = Hash(Symbol, StateValueType).new
      handlers.each do |_, handler|
        handler.registry(msg, state, from_edit: true)
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

    def is_admin?(chat_id, user_id, dirty = true)
      has_permission?(chat_id, user_id, :admin)
    end

    def has_permission?(chat_id, user_id, role, dirty = true)
      return false if chat_id > 0          # 私聊无权限
      if admins = Cache.get_admins chat_id # 从缓存中获取管理员列表
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
        spawn { refresh_admins chat_id } if dirty
        result
      else # 没有获得管理员列表，缓存并递归
        Cache.set_admins chat_id, get_chat_administrators(chat_id)
        has_permission?(chat_id, user_id, role, dirty: false)
      end
    end

    def refresh_admins(chat_id)
      Cache.set_admins chat_id, get_chat_administrators(chat_id)
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

    def debug(text)
      logger.debug text
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

    def send_message(chat_id : Int | String,
                     text : String,
                     parse_mode : String? = "Markdown",
                     disable_web_page_preview : Bool? = true,
                     disable_notification : Bool? = nil,
                     reply_to_message_id : Int32? = nil,
                     reply_markup : ReplyMarkup = nil) : TelegramBot::Message?
      super(
        chat_id: chat_id,
        text: text,
        parse_mode: parse_mode,
        disable_web_page_preview: disable_web_page_preview,
        disable_notification: disable_notification,
        reply_to_message_id: reply_to_message_id,
        reply_markup: reply_markup
      )
    end

    def edit_message_text(chat_id : Int | String | Nil = nil,
                          message_id : Int32? = nil,
                          inline_message_id : String? = nil,
                          text : String? = nil,
                          parse_mode : String? = "Markdown",
                          disable_web_page_preview : Bool? = true,
                          reply_markup : TelegramBot::InlineKeyboardMarkup? = nil) : TelegramBot::Message | Bool | Nil
      super(
        chat_id: chat_id,
        message_id: message_id,
        inline_message_id: inline_message_id,
        text: text,
        parse_mode: parse_mode,
        disable_web_page_preview: disable_web_page_preview,
        reply_markup: reply_markup
      )
    end

    NONE_FROM_USER = "Unknown"

    def send_welcome(chat : TelegramBot::Chat,
                     message_id : Int32?,
                     from_user : FromUser? = nil,
                     reply : Bool? = false,
                     reply_id : Int32? = nil,
                     last_delete : Bool? = true) : Bool
      chat_id = chat.id

      # 延迟清理欢迎消息和加群消息（根据设置）
      destory_task = ->(msg_id : Int32) {
        Model::CleanMode.working(chat_id, CleanDeleteTarget::Welcome) do
          spawn delete_message(chat_id, msg_id)
          if _delete_id = reply_id
            Model::AntiMessage.working chat_id, AntiTarget::JoinGroup do
              delete_message(chat_id, _delete_id)
            end
          end
        end
      }

      if welcome = KVStore.get_welcome(chat_id)
        disable_link_preview = KVStore.disabled_welcome_link_preview?(chat_id)
        text =
          (escape_markdown(welcome) || "Empty welcome content")
        text =
          if from_user
            vals = [from_user.fullname, chat.title, from_user.markdown_link, from_user.user_id]
            render text,
              ["fullname", "chatname", "mention", "userid"],
              vals
          else
            vals = [NONE_FROM_USER, NONE_FROM_USER, NONE_FROM_USER, NONE_FROM_USER]
            render text,
              ["fullname", "chatname", "mention", "userid"],
              vals
          end

        # 异步调用
        if reply
          spawn { delete_message chat_id, message_id } if last_delete
          spawn {
            sended_msg = send_message(
              chat_id,
              text: text,
              reply_to_message_id: reply_id,
              reply_markup: nil,
              disable_web_page_preview: disable_link_preview
            )

            if sended_msg # 根据设置延迟清理
              destory_task.call sended_msg.message_id
            end
          }
        else
          spawn {
            edit_message_text(
              chat_id,
              message_id: message_id,
              text: text,
              reply_markup: nil,
              disable_web_page_preview: disable_link_preview
            )
            # 根据设置延迟清理
            destory_task.call message_id
          }
        end
        true
      else
        false
      end
    end
  end
end
