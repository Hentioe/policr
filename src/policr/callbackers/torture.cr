# 2019-07-18 此文件需要重构！！！

module Policr
  DELAY_SHORT = 3

  callbacker Torture do
    alias DeleteTarget = CleanDeleteTarget

    def handle(query, msg, data)
      chat_id = msg.chat.id
      from_user_id = query.from.id
      target_id, _, chooese, photo = data

      is_photo = photo.to_i == 1
      chooese_i = chooese.to_i
      target_user_id = target_id.to_i
      message_id = msg.message_id

      join_msg = msg.reply_to_message
      join_msg_id =
        if join_msg
          join_msg.message_id
        end

      if chooese_i <= 0 # 管理员菜单

        if bot.is_admin? chat_id, from_user_id
          case chooese_i
          when 0
            passed(query, msg.chat, target_user_id, message_id, admin: FromUser.new(query.from), photo: is_photo, reply_msg: join_msg)
          when -1
            failed(
              chat_id,
              message_id,
              target_user_id,
              admin: FromUser.new(query.from),
              photo: is_photo,
              reply_msg: join_msg
            )
          end
        else
          bot.answer_callback_query(query.id, text: t("callback.no_permission"), show_alert: true)
        end
      else
        if target_user_id != from_user_id # 无关人士
          bot.answer_callback_query(query.id, text: t("unrelated_warning"), show_alert: true)
          return
        end

        if Model::TrueIndex.contains?(chat_id, msg.message_id, chooese) # 通过验证
          status = Cache.verification?(chat_id, target_user_id)
          unless status
            Cache.verification_init chat_id, target_user_id
            midcall UserJoinHandler do
              spawn bot.delete_message chat_id, message_id
              _handler.promptly_torture chat_id, join_msg_id, target_user_id, re: true
              return
            end
          end
          passed = ->{
            passed query, msg.chat, target_user_id, message_id, photo: is_photo, reply_msg: join_msg
          }
          case status
          when VerificationStatus::Init
            if KVStore.enabled_fault_tolerance?(chat_id) && !KVStore.custom(chat_id) # 容错模式处理
              if Model::ErrorCount.counting(chat_id, target_user_id) > 0             # 继续验证
                Cache.verification_next chat_id, target_user_id                      # 更新验证状态避免超时
                Model::ErrorCount.destory chat_id, target_user_id                    # 销毁错误记录
                midcall UserJoinHandler do
                  spawn bot.delete_message chat_id, message_id
                  _handler.promptly_torture chat_id, join_msg_id, target_user_id, re: true
                  return
                end
              else
                passed.call
              end
            else
              passed.call
            end
          when VerificationStatus::Next
            if Model::ErrorCount.counting(chat_id, target_user_id) > 0 # 继续验证
              Cache.verification_next chat_id, target_user_id          # 更新验证状态避免超时
              Model::ErrorCount.destory chat_id, target_user_id        # 销毁错误记录
              midcall UserJoinHandler do
                spawn bot.delete_message chat_id, message_id
                _handler.promptly_torture chat_id, join_msg_id, target_user_id, re: true
                return
              end
            else
              passed.call
            end
          when VerificationStatus::Slowed
            slow_with_receipt(query, chat_id, target_user_id, message_id)
          end
        else                                                                       # 未通过验证
          if KVStore.enabled_fault_tolerance?(chat_id) && !KVStore.custom(chat_id) # 容错模式处理
            fault_tolerance chat_id, target_user_id, message_id, query.id, join_msg, is_photo
          else
            bot.answer_callback_query(query.id, text: t("no_pass_alert"), show_alert: true)
            failed(chat_id, message_id, target_user_id, photo: is_photo, reply_msg: join_msg)
          end
        end
      end
    end

    def fault_tolerance(chat_id, user_id, message_id, query_id, join_msg, is_photo)
      join_msg_id =
        if join_msg
          join_msg.message_id
        end
      count = Model::ErrorCount.counting chat_id, user_id
      if count == 0                                 # 继续验证
        Cache.verification_next chat_id, user_id    # 更新验证状态避免超时
        Model::ErrorCount.one_time chat_id, user_id # 错误次数加一
        midcall UserJoinHandler do
          spawn bot.delete_message chat_id, message_id
          _handler.promptly_torture chat_id, join_msg_id, user_id, re: true
          return
        end
      else # 验证失败
        bot.answer_callback_query(query_id, text: t("no_pass_alert"), show_alert: true)
        failed(chat_id, message_id, user_id, photo: is_photo, reply_msg: join_msg)
      end
    end

    def passed(query : TelegramBot::CallbackQuery,
               chat : TelegramBot::Chat,
               target_user_id : Int32,
               message_id : Int32,
               admin : FromUser? = nil,
               photo = false,
               reply_msg : TelegramBot::Message? = nil)
      chat_id = chat.id
      reply_id =
        if reply_msg
          reply_msg.message_id
        end
      is_enabled_from = KVStore.enabled_from? chat_id

      destory_join_msg = ->{
        # 立即删除入群消息（如果没有启用来源调查）
        if !is_enabled_from && (_delete_msg_id = reply_id)
          Model::AntiMessage.working chat_id, ServiceMessage::JoinGroup do
            spawn bot.delete_message(chat_id, _delete_msg_id)
          end
        end
      }

      Cache.verification_passed chat_id, target_user_id # 更新验证状态
      Model::ErrorCount.destory chat_id, target_user_id # 销毁错误记录
      # 异步调用
      spawn bot.answer_callback_query(query.id, text: t("pass_alert")) unless admin

      text =
        if admin
          t("pass_by_admin", {user_id: target_user_id, admin: admin.markdown_link})
        else
          t("pass_by_self", {user_id: target_user_id})
        end

      if photo
        spawn bot.delete_message chat_id, message_id
        spawn {
          sended_msg = bot.send_message(
            chat_id,
            text: text,
            reply_to_message_id: reply_id
          )

          if sended_msg && !KVStore.enabled_record_mode?(chat_id)
            msg_id = sended_msg.message_id
            Schedule.after(DELAY_SHORT.seconds) do
              spawn bot.delete_message(chat_id, msg_id)
              destory_join_msg.call
            end
          end
        }
      else
        spawn {
          bot.edit_message_text(
            chat_id,
            message_id: message_id,
            text: text
          )

          unless KVStore.enabled_record_mode?(chat_id)
            schedule(DELAY_SHORT.seconds) do
              spawn bot.delete_message(chat_id, message_id)
              destory_join_msg.call
            end
          end
        }
      end

      if KVStore.enabled_welcome? chat_id
        from_user =
          if admin
            if reply_msg
              FromUser.new(reply_msg.from)
            end
          elsif reply_msg
            FromUser.new(query.from)
          end
        bot.send_welcome chat, from_user
      end
      # 初始化用户权限
      spawn bot.restrict_chat_member(
        chat_id,
        target_user_id,
        can_send_messages: true,
        can_send_media_messages: true,
        can_send_other_messages: true,
        can_add_web_page_previews: true
      )

      # 来源调查
      inform_from(chat_id, target_user_id) if is_enabled_from
    end

    def inform_from(chat_id : Int64, user_id : Int32)
      if from_list = KVStore.get_from(chat_id)
        index = -1
        btn = ->(text : String) {
          Button.new(text: text, callback_data: "From:#{user_id}:_:#{index += 1}")
        }
        markup = Markup.new
        from_list.each do |btn_text_list|
          markup << btn_text_list.map { |text| btn.call(text) }
        end
        join_msg_id = Cache.user_join_msg? user_id, chat_id
        if sended_msg = bot.send_message(
             chat_id,
             text: t("from.question"),
             reply_to_message_id: join_msg_id,
             reply_markup: markup
           )
          # 根据干净模式数据延迟清理来源调查
          _delete_from_msg_id = sended_msg.message_id
          Model::CleanMode.working(chat_id, DeleteTarget::From) do
            spawn bot.delete_message(chat_id, _delete_from_msg_id)
            # 删除入群消息
            if _delete_join_msg_id = join_msg_id
              Model::AntiMessage.working chat_id, ServiceMessage::JoinGroup do
                spawn bot.delete_message(chat_id, _delete_join_msg_id)
              end
            end
          end
        end
      end
    end

    private def slow_with_receipt(query : TelegramBot::CallbackQuery,
                                  chat_id : Int64,
                                  target_user_id : Int32,
                                  message_id : Int32)
      # 异步调用
      spawn bot.answer_callback_query(query.id, text: t("pass_slow_alert"))
      spawn { bot.edit_message_text(
        chat_id,
        message_id: message_id,
        text: t("pass_slow_receipt"),
        reply_markup: nil
      ) }
      bot.unban_chat_member(chat_id, target_user_id)
    end

    def failed(chat_id : Int64,
               message_id : Int32,
               user_id : Int32,
               admin : FromUser? = nil,
               timeout = false,
               photo = false,
               reply_msg : TelegramBot::Message? = nil)
      reply_id =
        if reply_msg
          reply_msg.message_id
        end
      Model::ErrorCount.destory chat_id, user_id # 销毁错误记录
      midcall UserJoinHandler do
        _handler.failed(chat_id, message_id, user_id, admin: admin, timeout: timeout, photo: photo, reply_id: reply_id)
      end
    end
  end
end
