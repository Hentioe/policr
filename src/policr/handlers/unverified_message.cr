module Policr
  handler UnverifiedMessage do
    @status : VerificationStatus?

    match do
      all_pass? [
        !deleted?,
        (user = msg.from),
        (status = Cache.verification?(msg.chat.id, user.id)),
        status == VerificationStatus::Init,
        from_group_chat?(msg),
        !msg.new_chat_members,
      ]
    end

    handle do
      spawn bot.delete_message(msg.chat.id, msg.message_id)

      deleted # 标记删除
    end
  end
end
