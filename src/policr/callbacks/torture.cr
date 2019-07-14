module Policr
  class TortureCallback < Callback
    alias VerifyStatus = Cache::VerifyStatus
    alias DeleteTarget = Policr::CleanDeleteTarget
    alias EnableStatus = Policr::EnableStatus

    def initialize(bot)
      super(bot, "Torture")
    end

    def handle(query, msg, report)
      chat_id = msg.chat.id
      from_user_id = query.from.id
      target_id, target_username, chooese, photo = report

      is_photo = photo.to_i == 1
      chooese_i = chooese.to_i
      target_user_id = target_id.to_i
      message_id = msg.message_id

      join_msg_id =
        if reply_msg = msg.reply_to_message
          reply_msg.message_id
        else
          nil
        end

      if chooese_i <= 0 # 管理员菜单

        if bot.is_admin? chat_id, from_user_id
          bot.log "The administrator ended the torture by: #{chooese_i}"
          case chooese_i
          when 0
            passed(query, chat_id, target_user_id, target_username, message_id, admin: FromUser.new(query.from), photo: is_photo, reply_id: join_msg_id)
          when -1
            failed(chat_id, message_id, target_user_id, target_username, admin: FromUser.new(query.from), photo: is_photo, reply_id: join_msg_id)
          end
        else
          bot.answer_callback_query(query.id, text: t("callback.no_permission"), show_alert: true)
        end
      else
        if target_user_id != from_user_id # 无关人士
          bot.log "Irrelevant User ID '#{from_user_id}' clicked on the verification inline keyboard button"
          bot.answer_callback_query(query.id, text: t("unrelated_warning"), show_alert: true)
          return
        end

        if Model::TrueIndex.contains?(chat_id, msg.message_id, chooese) # 通过验证
          status = Cache.verify?(chat_id, target_user_id)
          unless status
            Cache.verify_init chat_id, target_user_id
            midcall UserJoinHandler do
              spawn bot.delete_message chat_id, message_id
              handler.promptly_torture chat_id, join_msg_id, target_user_id, target_username, re: true
              return
            end
          end
          passed = ->{
            passed(query, chat_id, target_user_id,
              target_username, message_id,
              photo: is_photo, reply_id: join_msg_id)
          }
          case status
          when VerifyStatus::Init
            if KVStore.fault_tolerance?(chat_id) && !KVStore.custom(chat_id) # 容错模式处理
              if Model::ErrorCount.counting(chat_id, target_user_id) > 0     # 继续验证
                Cache.verify_next chat_id, target_user_id                    # 更新验证状态避免超时
                Model::ErrorCount.destory chat_id, target_user_id            # 销毁错误记录
                midcall UserJoinHandler do
                  spawn bot.delete_message chat_id, message_id
                  handler.promptly_torture chat_id, join_msg_id, target_user_id, target_username, re: true
                  return
                end
              else
                passed.call
              end
            else
              passed.call
            end
          when VerifyStatus::Next
            if Model::ErrorCount.counting(chat_id, target_user_id) > 0 # 继续验证
              Cache.verify_next chat_id, target_user_id                # 更新验证状态避免超时
              Model::ErrorCount.destory chat_id, target_user_id        # 销毁错误记录
              midcall UserJoinHandler do
                spawn bot.delete_message chat_id, message_id
                handler.promptly_torture chat_id, join_msg_id, target_user_id, target_username, re: true
                return
              end
            else
              passed.call
            end
          when VerifyStatus::Slow
            slow_with_receipt(query, chat_id, target_user_id, target_username, message_id)
          end
        else                                                               # 未通过验证
          if KVStore.fault_tolerance?(chat_id) && !KVStore.custom(chat_id) # 容错模式处理
            fault_tolerance chat_id, target_user_id, message_id, query.id, target_username, join_msg_id, is_photo
          else
            bot.log "Username '#{target_username}' did not pass verification"
            bot.answer_callback_query(query.id, text: t("no_pass_alert"), show_alert: true)
            failed(chat_id, message_id, target_user_id, target_username, photo: is_photo, reply_id: join_msg_id)
          end
        end
      end
    end

    def fault_tolerance(chat_id, user_id, message_id, query_id, username, join_msg_id, is_photo)
      count = Model::ErrorCount.counting chat_id, user_id
      if count == 0                                 # 继续验证
        Cache.verify_next chat_id, user_id          # 更新验证状态避免超时
        Model::ErrorCount.one_time chat_id, user_id # 错误次数加一
        midcall UserJoinHandler do
          spawn bot.delete_message chat_id, message_id
          handler.promptly_torture chat_id, join_msg_id, user_id, username, re: true
          return
        end
      else # 验证失败
        bot.log "User '#{user_id}' did not pass verification"
        bot.answer_callback_query(query_id, text: t("no_pass_alert"), show_alert: true)
        failed(chat_id, message_id, user_id, username, photo: is_photo, reply_id: join_msg_id)
      end
    end

    def passed(query, chat_id, target_user_id, target_username, message_id, admin = false, photo = false, reply_id : Int32? = nil)
      Cache.verify_passed chat_id, target_user_id       # 更新验证状态
      Model::ErrorCount.destory chat_id, target_user_id # 销毁错误记录
      bot.log "Username '#{target_username}' passed verification"
      # 异步调用
      spawn bot.answer_callback_query(query.id, text: t("pass_alert")) unless admin
      enabled_welcome = KVStore.enabled_welcome? chat_id
      text =
        if enabled_welcome && (welcome = KVStore.get_welcome chat_id)
          welcome
        elsif admin
          t("pass_by_admin", {user_id: target_user_id})
        else
          t("pass_by_self", {user_id: target_user_id})
        end
      # 异步调用
      if photo
        spawn bot.delete_message chat_id, message_id
        spawn {
          sended_msg = bot.send_message(chat_id: chat_id, text: text, reply_to_message_id: reply_id, reply_markup: nil, parse_mode: "markdown")

          if sended_msg && !KVStore.record_mode?(chat_id) && !enabled_welcome
            msg_id = sended_msg.message_id
            Schedule.after(5.seconds) { bot.delete_message(chat_id, msg_id) }
          end

          if sended_msg && enabled_welcome # 根据干净模式数据延迟清理欢迎消息
            msg_id = sended_msg.message_id
            Model::CleanMode.working(chat_id, DeleteTarget::Welcome) { bot.delete_message(chat_id, msg_id) }
          end
        }
      else
        spawn { bot.edit_message_text(chat_id: chat_id, message_id: message_id,
          text: text, reply_markup: nil, parse_mode: "markdown") }
      end

      # 非记录且没启用欢迎消息模式删除消息
      if !KVStore.record_mode?(chat_id) && !enabled_welcome && !photo
        Schedule.after(5.seconds) { bot.delete_message(chat_id, message_id) }
      end

      # 初始化用户权限
      bot.restrict_chat_member(chat_id, target_user_id, can_send_messages: true, can_send_media_messages: true, can_send_other_messages: true, can_add_web_page_previews: true)

      # 来源调查
      from_investigate(chat_id, message_id, target_username, target_user_id) if KVStore.enabled_from?(chat_id)
    end

    def from_investigate(chat_id, message_id, username, user_id)
      bot.log "From investigation of '#{username}'"
      if from_list = KVStore.get_from(chat_id)
        index = -1
        btn = ->(text : String) {
          Button.new(text: text, callback_data: "From:#{user_id}:#{username}:#{index += 1}")
        }
        markup = Markup.new
        from_list.each do |btn_text_list|
          markup << btn_text_list.map { |text| btn.call(text) }
        end
        reply_to_message_id = Cache.user_join_msg? user_id, chat_id
        sended_msg = bot.send_message(chat_id, t("from.question"), reply_to_message_id: reply_to_message_id, reply_markup: markup)
        # 根据干净模式数据延迟清理来源调查
        if sended_msg
          msg_id = sended_msg.message_id
          Model::CleanMode.working(chat_id, DeleteTarget::From) { bot.delete_message(chat_id, msg_id) }
        end
      end
    end

    private def slow_with_receipt(query, chat_id, target_user_id, target_username, message_id)
      bot.log "Username '#{target_username}' verification is a bit slower"

      # 异步调用
      spawn bot.answer_callback_query(query.id, text: t("pass_slow_alert"))
      spawn { bot.edit_message_text(chat_id: chat_id, message_id: message_id,
        text: t("pass_slow_receipt"), reply_markup: nil) }
      bot.unban_chat_member(chat_id, target_user_id)
    end

    def failed(chat_id, message_id, user_id, username, admin : FromUser? = nil, timeout = false, photo = false, reply_id : Int32? = nil)
      Model::ErrorCount.destory chat_id, user_id # 销毁错误记录
      midcall UserJoinHandler do
        handler.failed(chat_id, message_id, user_id, username, admin: admin, timeout: timeout, photo: photo, reply_id: reply_id)
      end
    end
  end
end
