require "telegram_bot"
require "schedule"

module Policr
  DEFAULT_TORTURE_SEC = 45 # 默认验证等待时长（秒）

  class Bot < TelegramBot::Bot
    FROM_TIPS =
      <<-TEXT
        您正在设置来源调查，一个具体的例子：

        ```
        -短来源1 -短来源2
        -长长长长长来源3
        -长长长长长来源4
        ```
        如上，每一个来源需要前缀「-」，当多个来源位于同一行时将并列显示，否则独占一行。
        消息不要使用 `Markdown` 格式，在 PC 客户端可能需要 `<Ctrl>+<Enter>` 组合键才能换行。请注意，**只有回复本消息才会被认为是设置来源调查**，并且随着机器人的重启，本消息很可能存在回复有效期。
        TEXT

    alias TortureTimeType = Cache::TortureTimeType
    alias VerifyStatus = Cache::VerifyStatus

    include TelegramBot::CmdHandler

    getter self_id : Int64
    getter handlers = Hash(Symbol, Handler).new
    getter callbacks = Hash(Symbol, Callback).new

    def initialize
      super(Policr.username, Policr.token)

      me = get_me || raise Exception.new("Failed to get bot data")
      @self_id = me["id"].as_i64

      handlers[:join_user] = JoinUserHandler.new self
      handlers[:join_bot] = JoinBotHandler.new self
      handlers[:unverified_message] = UnverifiedMessageHandler.new self
      handlers[:halal_message] = HalalMessageHandler.new self
      handlers[:from_setting] = FromSettingHandler.new self
      handlers[:verify_time_setting] = VerifyTimeSettingHandler.new self

      callbacks[:torture] = TortureCallback.new self
      callbacks[:baned_menu] = BanedMenuCallback.new self
      callbacks[:bot_join] = BotJoinCallback.new self
      callbacks[:from] = FromCallback.new self

      cmd "ping" do |msg|
        reply msg, "pong"
      end

      cmd "start" do |msg|
        text =
          "欢迎使用 ε٩(๑> ₃ <)۶з 我是强大的审核机器人 PolicrBot。我的主要功能不会主动开启，需要通过指令手动启用或设置。推荐在 Github 上查看我的指令用法 ~"
        send_message(msg.chat.id, text, reply_to_message_id: msg.message_id, parse_mode: "markdown")
      end

      cmd "from" do |msg|
        role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
        if (user = msg.from) && has_permission?(msg.chat.id, user.id, role)
          sended_msg = send_message(msg.chat.id, FROM_TIPS, reply_to_message_id: msg.message_id, parse_mode: "markdown")
          if sended_msg
            Cache.carying_from_setting_msg sended_msg.message_id
          end
        end
      end

      cmd "enable_examine" do |msg|
        role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
        if (user = msg.from) && has_permission?(msg.chat.id, user.id, role)
          text = "已启动审核。包含: 新入群成员主动验证、清真移除、清真消息封禁等功能被开启。"
          if is_admin(msg.chat.id, @self_id.to_i32)
            DB.enable_examine(msg.chat.id)
          else
            text = "不给权限还想让人家干活，做梦。"
          end
          reply msg, text
        end
      end

      cmd "disable_examine" do |msg|
        role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
        if (user = msg.from) && has_permission?(msg.chat.id, user.id, role)
          DB.disable_examine(msg.chat.id)
          text = "已禁用审核。包含: 新入群成员主动验证、清真移除、清真消息封禁等功能被关闭。"
          reply msg, text
        end
      end

      cmd "enable_from" do |msg|
        role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
        if (user = msg.from) && has_permission?(msg.chat.id, user.id, role)
          if DB.get_chat_from(msg.chat.id)
            DB.enable_chat_from(msg.chat.id)
            text = "已启用来源调查并沿用了之前的设置。如果需要重新设置调查列表，请使用 `/from` 指令。"
            send_message(msg.chat.id, text, reply_to_message_id: msg.message_id, parse_mode: "markdown")
          else
            text = "没有检测到之前的来源设置，请使用 `/from` 指令完成设置。"
            send_message(msg.chat.id, text, reply_to_message_id: msg.message_id, parse_mode: "markdown")
          end
        end
      end

      cmd "disable_from" do |msg|
        role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
        if (user = msg.from) && has_permission?(msg.chat.id, user.id, role)
          DB.disable_chat_from(msg.chat.id)

          text = "已禁用来源调查功能，启用请使用 `/from` 指令完成设置。"
          text = "已禁用来源调查功能，相关设置将会在下次启用时继续沿用。" if DB.get_chat_from(msg.chat.id)
          send_message(msg.chat.id, text, reply_to_message_id: msg.message_id, parse_mode: "markdown")
        end
      end

      cmd "torture_sec" do |msg|
        role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
        if (user = msg.from) && has_permission?(msg.chat.id, user.id, role)
          current = "此群组当前使用 Bot 默认的时长（#{DEFAULT_TORTURE_SEC} 秒）"
          if sec = DB.get_torture_sec(msg.chat.id, -1)
            current = "此群组当前已设置时长（#{sec} 秒）" if sec != -1
          end

          text = "欢迎设置入群验证的等待时间，#{current}。请使用有效的数字作为秒数回复此消息以设置或更新独立的验证时间。注意：此消息可能因为机器人的重启而失效，请即时回复。"
          if send_message = reply msg, text
            Cache.carving_torture_time_msg_sec(send_message.message_id)
          end
        end
      end

      cmd "torture_min" do |msg|
        role = DB.trust_admin?(msg.chat.id) ? :admin : :creator
        if (user = msg.from) && has_permission?(msg.chat.id, user.id, role)
          current = "此群组当前使用 Bot 默认的时长（#{DEFAULT_TORTURE_SEC} 秒）"
          if sec = DB.get_torture_sec(msg.chat.id, -1)
            current = "此群组当前已设置时长（#{sec} 秒）" if sec != -1
          end

          text = "欢迎设置入群验证的等待时间，#{current}。请使用有效的数字作为分钟数回复此消息以设置或更新独立的验证时间，支持小数。注意：此消息可能因为机器人的重启而失效，请即时回复。"
          if send_message = reply msg, text
            Cache.carving_torture_time_msg_min(send_message.message_id)
          end
        end
      end

      cmd "trust_admin" do |msg|
        if (user = msg.from) && has_permission?(msg.chat.id, user.id, :creator)
          DB.trust_admin msg.chat.id
          reply msg, "已赋予管理员使用指令调整大部分设置的权力。"
        end
      end

      cmd "distrust_admin" do |msg|
        if (user = msg.from) && has_permission?(msg.chat.id, user.id, :creator)
          DB.distrust_admin msg.chat.id
          reply msg, "已回收其它管理员使用指令调整设置的权力。"
        end

        cmd "token" do |_msg|
          case msg.chat.type
          when "supergroup" # 生成令牌
            nil
          when "private" # 获取令牌列表
            nil
          end
        end
      end
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
          callback.handle(query, message, report.skip(1)) if callback.match?(call_name)
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

    def handle(msg : TelegramBot::Message)
      handlers.each do |_, handler|
        handler.registry(msg)
      end

      super
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
