require "telegram_bot"
require "schedule"

module Policr
  SAFE_MSG_SIZE     =  2
  TORTURE_SEC       = 25
  ARABIC_CHARACTERS = /^[\X{0600}-\x{06FF}-\x{0750}-\x{077F}-\x{08A0}-\x{08FF}-\x{FB50}-\x{FDFF}-\x{FE70}-\x{FEFF}-\x{10E60}-\x{10E7F}-\x{1EC70}-\x{1ECBF}-\x{1ED00}-\x{1ED4F}-\x{1EE00}-\x{1EEFF} ]+$/

  class Bot < TelegramBot::Bot
    include TelegramBot::CmdHandler

    @auth_status = Hash(Int32, Bool).new

    def initialize
      super("PolicrBot", Policr.token)

      cmd "ping" do |msg|
        reply msg, "pong"
      end
    end

    private def handle_torture(query, chooese, chat_id, target_user_id, from_user_id, message_id)
      if target_user_id != from_user_id
        logger.info "Irrelevant User ID '#{from_user_id}' clicked on the verification inline keyboard button"
        answer_callback_query(query.id, text: "(#`Д´)ﾉ 请无关人员不要来搞事", show_alert: true)
        return
      end
      if chooese.to_i == 3
        status = @auth_status[target_user_id]?
        @auth_status[target_user_id] = true
        if status == false
          logger.info "User ID '#{target_user_id}' passed verification"
          answer_callback_query(query.id, text: "验证通过", show_alert: true)
          edit_message_text(chat_id: chat_id, message_id: message_id,
            text: "(*´∀`)~♥ 恭喜您通过了验证，逃过一劫。", reply_markup: nil)
        elsif status == nil
          logger.info "User ID '#{target_user_id}' verification is a bit slower"
          answer_callback_query(query.id, text: "验证通过，但是晚了一点点，再去试试？", show_alert: true)
          edit_message_text(chat_id: chat_id, message_id: message_id,
            text: "(´ﾟдﾟ`) 他通过了验证，但是手慢了那么一点点，再给他一次机会……", reply_markup: nil)
          unban_chat_member(chat_id, target_user_id)
        end
      else
        logger.info "User ID '#{target_user_id}' did not pass verification"
        answer_callback_query(query.id, text: "未通过验证", show_alert: true)
        failed_verification(chat_id, message_id, target_user_id)
      end
    end

    def handle_baned_menu(query, chat_id, target_user_id, from_user_id, message_id)
      operator = get_chat_member(chat_id, from_user_id)
      if operator.status == "creator" || operator.status == "admin"
        begin
          logger.info "User ID '#{target_user_id}' has been unbanned by the administrator"
          unban_r = unban_chat_member(chat_id, target_user_id)
          edit_message_text(chat_id: chat_id, message_id: message_id,
            text: "(,,・ω・,,) 已经被解封了，快通知他回来。", reply_markup: nil) if unban_r
        rescue ex : TelegramBot::APIException
          _, reason = get_failure_code_with_reason(ex)
          answer_callback_query(query.id, text: "解封失败，#{reason}", show_alert: true)
          logger.info "User ID '#{target_user_id}' unsealing failed, reason: #{reason}"
        end
      else
        logger.info "User ID '#{from_user_id}' without permission Click to unbanned button"
        answer_callback_query(query.id, text: "你既然不是管理员，那就是他的同伙，不听你的", show_alert: true)
      end
    end

    def handle(query : TelegramBot::CallbackQuery)
      if (data = query.data) && (message = query.message)
        report = data.split(":")
        if report.size < 3
          logger.info "'#{get_fullname(query.from)}' clicked on the invalid inline keyboard button"
          answer_callback_query(query.id, text: "( ×ω× ) 这副内联键盘已经失效了哦", show_alert: true)
          return
        end
        chat_id = message.chat.id
        from_user_id = query.from.id
        type, target_id, chooese = report
        case type
        when "Torture"
          handle_torture(query, chooese, chat_id, target_id.to_i, from_user_id, message.message_id)
        when "BanedMenu"
          handle_baned_menu(query, chat_id, target_id.to_i, from_user_id, message.message_id)
        end
      end
    end

    private def failed_verification(chat_id, message_id, user_id)
      logger.info "User ID '#{user_id}' has not been verified and has been banned"
      edit_message_text(chat_id: chat_id, message_id: message_id,
        text: "(〒︿〒) 他还没来得及打招呼就离开了我们。", reply_markup: add_banned_menu(user_id))
      kick_chat_member(chat_id, user_id)
    end

    def handle(msg : TelegramBot::Message)
      new_members = msg.new_chat_members
      new_members.each do |member|
        name = get_fullname(member)
        name =~ ARABIC_CHARACTERS ? tick_with_report(msg, member) : torture_action(msg, member)
      end if new_members
      if (text = msg.text) && (user = msg.from)
        tick_with_report(msg, user) if (text.size > SAFE_MSG_SIZE && text =~ ARABIC_CHARACTERS)
      end
    end

    private def torture_action(msg, member)
      name = get_fullname(member)
      logger.info "Start to torture '#{name}'"
      source_text = "两个黄鹂鸣翠柳"
      text = "请在 #{TORTURE_SEC} 秒内选出「#{source_text}」的下一句"
      reply_id = msg.message_id
      member_id = member.id.to_s
      ikb_list = TelegramBot::InlineKeyboardMarkup.new
      ikb_list << [TelegramBot::InlineKeyboardButton.new(text: "朝辞白帝彩云间", callback_data: "Torture:#{member_id}:1")]
      ikb_list << [TelegramBot::InlineKeyboardButton.new(text: "忽闻岸上踏歌声", callback_data: "Torture:#{member_id}:2")]
      ikb_list << [TelegramBot::InlineKeyboardButton.new(text: "一行白鹭上青天", callback_data: "Torture:#{member_id}:3")]
      sended_msg = send_message(msg.chat.id, text, reply_to_message_id: reply_id, reply_markup: ikb_list)
      @auth_status[member.id] = false
      if sended_msg && (message_id = sended_msg.message_id)
        Schedule.after(TORTURE_SEC.seconds) do
          unless @auth_status[member.id]?
            logger.info "User '#{name}' torture time expired and has been banned"
            @auth_status.delete member.id
            failed_verification(msg.chat.id, message_id, member.id)
          end
        end
      end
    end

    private def tick_with_report(msg, member)
      name = get_fullname(member)
      logger.info "Found a halal '#{name}'"
      sended_msg = reply msg, "d(`･∀･)b 诶发现一名清真，看我干掉它……"
      if sended_msg
        begin
          kick_r = kick_chat_member(msg.chat.id, member.id)
          member_id = member.id
          edit_message_text(chat_id: sended_msg.chat.id, message_id: sended_msg.message_id,
            text: "(ﾉ>ω<)ﾉ 已成功丢出去一只清真，真棒！", reply_markup: add_banned_menu(member_id)) if kick_r
          logger.info "Halal '#{name}' has been banned"
        rescue ex : TelegramBot::APIException
          edit_message_text(chat_id: sended_msg.chat.id, message_id: sended_msg.message_id,
            text: "╰(〒皿〒)╯ 啥情况，这枚清真移除失败了。") unless kick_r
          _, reason = get_failure_code_with_reason(ex)
          logger.info "Halal '#{name}' banned failure, reason: #{reason}"
        end
      end
    end

    private def add_banned_menu(member_id)
      ikb_list = TelegramBot::InlineKeyboardMarkup.new
      ikb_list << TelegramBot::InlineKeyboardButton.new(text: "解除封禁", callback_data: "BanedMenu:#{member_id}:unban")
      ikb_list
    end

    private def get_fullname(member)
      first_name = member.first_name
      last_name = member.last_name ? " #{member.last_name}" : ""
      "#{first_name}#{last_name}"
    end

    private def get_failure_code_with_reason(ex : TelegramBot::APIException)
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
