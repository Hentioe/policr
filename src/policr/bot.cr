require "telegram_bot"
require "schedule"

module Policr
  SAFE_MSG_SIZE     =  2
  TORTURE_SEC       = 25
  ARABIC_CHARACTERS = /^[\x{0600}-\x{06FF}-\x{0750}-\x{077F}-\x{08A0}-\x{08FF}-\x{FB50}-\x{FDFF}-\x{FE70}-\x{FEFF}-\x{10E60}-\x{10E7F}-\x{1EC70}-\x{1ECBF}-\x{1ED00}-\x{1ED4F}-\x{1EE00}-\x{1EEFF} ]+$/

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

  enum VeryfiStatus
    Init
    Pass
    Slow
  end

  class Bot < TelegramBot::Bot
    alias Button = TelegramBot::InlineKeyboardButton
    alias Markup = TelegramBot::InlineKeyboardMarkup

    include TelegramBot::CmdHandler

    @verify_status = Hash(Int32, VeryfiStatus).new

    @@from_chats = Set(Int32).new

    def initialize
      super(Policr.username, Policr.token)

      cmd "ping" do |msg|
        reply msg, "pong"
      end

      cmd "start" do |msg|
        text =
          "欢迎使用 ε٩(๑> ₃ <)۶з 我是强大的审核机器人 PolicrBot。只需要将我加入到您的群组中，并给予 `admin` 权限，便会自动开始工作。"
        send_message(msg.chat.id, text, reply_to_message_id: msg.message_id, parse_mode: "markdown")
      end

      cmd "from" do |msg|
        sended_msg = send_message(msg.chat.id, FROM_TIPS, reply_to_message_id: msg.message_id, parse_mode: "markdown")
        if sended_msg
          @@from_chats << sended_msg.message_id
        end
      end
    end

    private def verified_with_receipt(query, chat_id, target_user_id, target_username, message_id, admin = false)
      @verify_status[target_user_id] = VeryfiStatus::Pass
      logger.info "Username '#{target_username}' passed verification"

      answer_callback_query(query.id, text: "验证通过", show_alert: true) unless admin
      text = "(*´∀`)~♥ 恭喜您通过了验证，逃过一劫。"
      text = "Σ(*ﾟдﾟﾉ)ﾉ 这家伙走后门进来的，大家快喷他。" if admin

      edit_message_text(chat_id: chat_id, message_id: message_id,
        text: text, reply_markup: nil)

      from_investigate(chat_id, message_id, target_username, target_user_id)
    end

    private def unverified_with_receipt(chat_id, message_id, user_id, username, admin = false)
      @verify_status.delete user_id
      logger.info "Username '#{username}' has not been verified and has been banned"

      text = "(〒︿〒) 他没能挺过这一关，永久的离开了我们。"
      text = "(|||ﾟдﾟ) 太残忍了，独裁者直接干掉了他。" if admin
      edit_message_text(chat_id: chat_id, message_id: message_id,
        text: text, reply_markup: add_banned_menu(user_id, username))

      kick_chat_member(chat_id, user_id)
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

        status = @verify_status[target_user_id]?
        verified_with_receipt(query, chat_id, target_user_id, target_username, message_id) if status == VeryfiStatus::Init
        slow_with_receipt(query, chat_id, target_user_id, target_username, message_id) if status == VeryfiStatus::Slow
      elsif chooese_i <= 0
        if is_admin(chat_id, from_user_id)
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

    def handle_baned_menu(query, chat_id, target_user_id, target_username, from_user_id, message_id)
      unless is_admin(chat_id, from_user_id)
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

    private def is_admin(chat_id, user_id)
      operator = get_chat_member(chat_id, user_id)
      operator.status == "creator" || operator.status == "admin"
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
        end
      }
      if (data = query.data) && (message = query.message)
        _handle.call(data, message)
      end
    end

    def handle(msg : TelegramBot::Message)
      new_members = msg.new_chat_members
      new_members.each do |member|
        name = get_fullname(member)
        name =~ ARABIC_CHARACTERS ? tick_halal_with_receipt(msg, member) : torture_action(msg, member)
      end if new_members

      if (text = msg.text) && (user = msg.from)
        tick_halal_with_receipt(msg, user) if (text.size > SAFE_MSG_SIZE && text =~ ARABIC_CHARACTERS)
      end

      if (user = msg.from) && (reply_msg = msg.reply_to_message) && (reply_msg_id = reply_msg.message_id) && @@from_chats.includes?(reply_msg_id) && is_admin(msg.chat.id, user.id)
        logger.info "Enable From Investigate for ChatID '#{msg.chat.id}'"
        DB.put_chat_from(msg.chat.id, msg.text)
      end

      super
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

    QUESTION_TEXT = "两个黄鹂鸣翠柳"

    private def torture_action(msg, member)
      name = get_fullname(member)
      logger.info "Start to torture '#{name}'"
      question = "请在 #{TORTURE_SEC} 秒内选出「#{QUESTION_TEXT}」的下一句"
      reply_id = msg.message_id
      member_id = member.id.to_s
      member_username = member.username

      btn = ->(text : String, chooese_id : Int32) {
        Button.new(text: text, callback_data: "Torture:#{member_id}:#{member_username}:#{chooese_id}")
      }
      markup = Markup.new
      markup << [btn.call("朝辞白帝彩云间", 1)]
      markup << [btn.call("忽闻岸上踏歌声", 2)]
      markup << [btn.call("一行白鹭上青天", 3)]
      markup << [btn.call("人工通过", 0), btn.call("人工封禁", -1)]
      sended_msg = send_message(msg.chat.id, question, reply_to_message_id: reply_id, reply_markup: markup)

      @verify_status[member.id] = VeryfiStatus::Init
      ban_task = ->(message_id : Int32) {
        if @verify_status[member.id]? == VeryfiStatus::Init
          logger.info "User '#{name}' torture time expired and has been banned"
          @verify_status[member.id] = VeryfiStatus::Slow
          unverified_with_receipt(msg.chat.id, message_id, member.id, member.username)
        end
      }

      ban_timer = ->(message_id : Int32) { Schedule.after(TORTURE_SEC.seconds) { ban_task.call(message_id) } }
      if sended_msg && (message_id = sended_msg.message_id)
        ban_timer.call(message_id)
      end
    end

    private def tick_halal_with_receipt(msg, member)
      name = get_fullname(member)
      logger.info "Found a halal '#{name}'"
      sended_msg = reply msg, "d(`･∀･)b 诶发现一名清真，看我干掉它……"

      if sended_msg
        begin
          kick_chat_member(msg.chat.id, member.id)
          member_id = member.id
          edit_message_text(chat_id: sended_msg.chat.id, message_id: sended_msg.message_id,
            text: "(ﾉ>ω<)ﾉ 已成功丢出去一只清真，真棒！", reply_markup: add_banned_menu(member_id, member.username))
          logger.info "Halal '#{name}' has been banned"
        rescue ex : TelegramBot::APIException
          edit_message_text(chat_id: sended_msg.chat.id, message_id: sended_msg.message_id,
            text: "╰(〒皿〒)╯ 啥情况，这枚清真移除失败了。")
          _, reason = get_error_code_with_reason(ex)
          logger.info "Halal '#{name}' banned failure, reason: #{reason}"
        end
      end
    end

    private def add_banned_menu(user_id, username)
      markup = Markup.new
      markup << Button.new(text: "解除封禁", callback_data: "BanedMenu:#{user_id}:#{username}::unban")
      markup
    end

    private def get_fullname(member)
      first_name = member.first_name
      last_name = member.last_name ? " #{member.last_name}" : ""
      "#{first_name}#{last_name}"
    end

    private def get_error_code_with_reason(ex : TelegramBot::APIException)
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
