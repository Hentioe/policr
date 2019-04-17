require "telegram_bot"
require "schedule"

module Policr
  SAFE_MSG_SIZE       =  2 # 消息的安全长度
  DEFAULT_TORTURE_SEC = 45 # 默认验证等待时长（秒）

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

  class Bot < TelegramBot::Bot
    alias TortureTimeType = Cache::TortureTimeType
    alias VerifyStatus = Cache::VerifyStatus

    include TelegramBot::CmdHandler

    getter self_id : Int64
    getter handlers = Hash(Symbol, Handler).new

    def initialize
      super(Policr.username, Policr.token)

      me = get_me || raise Exception.new("Failed to get bot data")
      @self_id = me["id"].as_i64

      handlers[:join_user] = JoinUserHandler.new self
      handlers[:join_bot] = JoinBotHandler.new self
      handlers[:unverified_message] = UnverifiedMessage.new self
      handlers[:halal_message] = HalalMessageHandler.new self

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
      end

      cmd "token" do |msg|
        case msg.chat.type
        when "supergroup" # 生成令牌
          nil
        when "private" # 获取令牌列表
          nil
        end
      end
    end

    private def verified_with_receipt(query, chat_id, target_user_id, target_username, message_id, admin = false)
      Cache.verify_passed(target_user_id)
      logger.info "Username '#{target_username}' passed verification"

      answer_callback_query(query.id, text: "验证通过", show_alert: true) unless admin
      text = "(*´∀`)~♥ 恭喜您通过了验证，逃过一劫。"
      text = "Σ(*ﾟдﾟﾉ)ﾉ 这家伙走后门进来的，大家快喷他。" if admin

      edit_message_text(chat_id: chat_id, message_id: message_id,
        text: text, reply_markup: nil)

      restrict_chat_member(chat_id, target_user_id, can_send_messages: true)

      from_investigate(chat_id, message_id, target_username, target_user_id) if DB.enabled_from?(chat_id)
    end

    private def slow_with_receipt(query, chat_id, target_user_id, target_username, message_id)
      logger.info "Username '#{target_username}' verification is a bit slower"

      answer_callback_query(query.id, text: "验证通过，但是晚了一点点，再去试试？", show_alert: true)
      edit_message_text(chat_id: chat_id, message_id: message_id,
        text: "(´ﾟдﾟ`) 他通过了验证，但是手慢了那么一点点，再给他一次机会……", reply_markup: nil)
      unban_chat_member(chat_id, target_user_id)
    end

    private def handle_torture(query, chooese, chat_id, target_user_id, target_username, from_user_id, message_id)
      chooese_i = chooese.to_i

      if chooese_i == 3
        if target_user_id != from_user_id
          logger.info "Irrelevant User ID '#{from_user_id}' clicked on the verification inline keyboard button"
          answer_callback_query(query.id, text: "(#`Д´)ﾉ 请无关人员不要来搞事", show_alert: true)
          return
        end

        status = Cache.verify?(target_user_id)
        verified_with_receipt(query, chat_id, target_user_id, target_username, message_id) if status == VerifyStatus::Init
        slow_with_receipt(query, chat_id, target_user_id, target_username, message_id) if status == VerifyStatus::Slow
      elsif chooese_i <= 0
        role = DB.trust_admin?(chat_id) ? :admin : :creator

        if has_permission? chat_id, from_user_id, role
          logger.info "The administrator ended the torture by: #{chooese_i}"
          case chooese_i
          when 0
            verified_with_receipt(query, chat_id, target_user_id, target_username, message_id, admin: true)
          when -1
            unverified_with_receipt(chat_id, message_id, target_user_id, target_username, admin: true)
          end
        else
          answer_callback_query(query.id, text: "你既然不是管理员，那就是他的同伙，不听你的", show_alert: true)
        end
      else
        logger.info "Username '#{target_username}' did not pass verification"
        answer_callback_query(query.id, text: "未通过验证", show_alert: true)
        unverified_with_receipt(chat_id, message_id, target_user_id, target_username)
      end
    end

    def unverified_with_receipt(chat_id, message_id, user_id, username, admin = false)
      if (handler = handlers[:join_user]?) && handler.is_a?(JoinUserHandler)
        handler.unverified_with_receipt(chat_id, message_id, user_id, username, admin)
      end
    end

    def handle_baned_menu(query, chat_id, target_user_id, target_username, from_user_id, message_id)
      role = DB.trust_admin?(chat_id) ? :admin : :creator

      unless has_permission? chat_id, from_user_id, role
        logger.info "User ID '#{from_user_id}' without permission click to unbanned button"
        answer_callback_query(query.id, text: "你既然不是管理员，那就是他的同伙，不听你的", show_alert: true)
        return
      end

      begin
        logger.info "Username '#{target_username}' has been unbanned by the administrator"
        unban_r = unban_chat_member(chat_id, target_user_id)
        markup = Markup.new
        markup << Button.new(text: "叫 TA 回来", url: "t.me/#{target_username}")
        edit_message_text(chat_id: chat_id, message_id: message_id,
          text: "(,,・ω・,,) 已经被解封了，让他注意。", reply_markup: markup) if unban_r
      rescue ex : TelegramBot::APIException
        _, reason = get_error_code_with_reason(ex)
        answer_callback_query(query.id, text: "解封失败，#{reason}", show_alert: true)
        logger.info "Username '#{target_username}' unsealing failed, reason: #{reason}"
      end
    end

    def handle_from(query, chooese_id, chat_id, target_user_id, target_username, from_user_id, message_id)
      unless from_user_id == target_user_id
        logger.info "Unrelated User ID '#{from_user_id}' click to From Investigate button"
        answer_callback_query(query.id, text: "又不是问你，自作多情", show_alert: true)
        return
      end

      logger.info "Username '#{target_username}' has selected from: #{chooese_id}"

      all_from = Array(String).new
      if from_list = DB.get_chat_from(chat_id)
        from_list.each do |btn_list|
          btn_list.each { |btn_text| all_from << btn_text }
        end
      end
      edit_message_text(chat_id: chat_id, message_id: message_id,
        text: "原来是从「#{all_from[chooese_id]?}」过来的，大家心里已经有数了。")
    end

    def handle_restrict_bot(query, chooese_id, chat_id, bot_id, from_user_id, message_id)
      role = DB.trust_admin?(chat_id) ? :admin : :creator

      unless has_permission? chat_id, from_user_id, role
        logger.info "User ID '#{from_user_id}' without permission click to unrestrict button"
        answer_callback_query(query.id, text: "你既然不是管理员，那就是它的同伙，不听你的", show_alert: true)
        return
      end

      text = "已解除限制，希望是个有用的机器人。"
      case chooese_id
      when 0
        restrict_chat_member(chat_id, bot_id, can_send_messages: true)
      when -1
        kick_chat_member(chat_id, bot_id)
        text = "已经被移除啦~安全危机解除！"
      else
        text = "此消息的内联键盘功能已经过时了，没有进行任何操作~"
      end
      edit_message_text(chat_id: chat_id, message_id: message_id,
        text: text, reply_markup: nil)
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

    def handle(query : TelegramBot::CallbackQuery)
      _handle = ->(data : String, message : TelegramBot::Message) {
        report = data.split(":")
        if report.size < 4
          logger.info "'#{get_fullname(query.from)}' clicked on the invalid inline keyboard button"
          answer_callback_query(query.id, text: "( ×ω× ) 这副内联键盘已经失效了哦", show_alert: true)
          return
        end

        chat_id = message.chat.id
        from_user_id = query.from.id
        operate, target_id, target_username, chooese = report
        case operate
        when "Torture"
          handle_torture(query, chooese, chat_id, target_id.to_i, target_username, from_user_id, message.message_id)
        when "BanedMenu"
          handle_baned_menu(query, chat_id, target_id.to_i, target_username, from_user_id, message.message_id)
        when "From"
          handle_from(query, chooese.to_i, chat_id, target_id.to_i, target_username, from_user_id, message.message_id)
        when "BotJoin"
          handle_restrict_bot(query, chooese.to_i, chat_id, target_id.to_i, from_user_id, message.message_id)
        end
      }
      if (data = query.data) && (message = query.message)
        _handle.call(data, message)
      end
    end

    def handle(msg : TelegramBot::Message)
      role = DB.trust_admin?(msg.chat.id) ? :admin : :creator

      handlers.each do |_, handler|
        handler.registry(msg)
      end

      # 回复消息设置来源调查列表
      if (user = msg.from) && (reply_msg = msg.reply_to_message) && (reply_msg_id = reply_msg.message_id) && Cache.from_setting_msg?(reply_msg_id) && has_permission?(msg.chat.id, user.id, role)
        logger.info "Enable From Investigate for ChatID '#{msg.chat.id}'"
        DB.put_chat_from(msg.chat.id, msg.text)
        reply msg, "已完成设置。"
      end

      # 回复消息设置验证时间
      if (user = msg.from) && (text = msg.text) && (reply_msg = msg.reply_to_message) && (reply_msg_id = reply_msg.message_id) && (time_type = Cache.torture_time_msg?(reply_msg_id)) && has_permission?(msg.chat.id, user.id, role)
        sec = case time_type
              when TortureTimeType::Sec
                text.to_i
              when TortureTimeType::Min
                (60 * (text.to_f)).to_i
              end
        DB.set_torture_sec(msg.chat.id, sec)
        reply msg, "已完成设置。"
      end

      super
    end

    def restrict_bot(msg, bot)
      restrict_chat_member(msg.chat.id, bot.id, can_send_messages: false)

      btn = ->(text : String, chooese_id : Int32) {
        Button.new(text: text, callback_data: "BotJoin:#{bot.id}:[none]:#{chooese_id}")
      }
      markup = Markup.new
      markup << [btn.call("解除限制", 0), btn.call("直接移除", -1)]
      send_message(msg.chat.id, "抓到一个新加入的机器人，安全考虑已对其进行限制。如有需要可自行解除，否则请移除。", reply_to_message_id: msg.message_id, reply_markup: markup)
      logger.info "Bot '#{bot.id}' has been restricted"
    end

    def from_investigate(chat_id, message_id, username, user_id)
      logger.info "From investigation of '#{username}'"
      if from_list = DB.get_chat_from(chat_id)
        index = -1
        btn = ->(text : String) {
          Button.new(text: text, callback_data: "From:#{user_id}:#{username}:#{index += 1}")
        }
        markup = Markup.new
        from_list.each do |btn_text_list|
          markup << btn_text_list.map { |text| btn.call(text) }
        end
        send_message(chat_id, "欢迎 @#{username} 来到这里，告诉大家你从哪里来的吧？小手轻轻一点就行了~", reply_to_message_id: message_id, reply_markup: markup)
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
