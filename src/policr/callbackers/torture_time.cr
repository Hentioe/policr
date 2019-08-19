module Policr
  callbacker TortureTime do
    def handle(query, msg, data)
      target_group do
        sec = data[0]

        Cache.carving_torture_time_msg _chat_id, msg.message_id
        # 储存设置
        KVStore.set_torture_sec(_group_id, sec.to_i)
        # 更新设置时间消息文本
        bot.edit_message_text(
          _chat_id,
          message_id: msg.message_id,
          text: create_text(_group_id, _group_name),
          reply_markup: create_markup
        )
        # 响应成功
        bot.answer_callback_query(query.id)
      end
    end

    def create_text(group_id, group_name)
      midcall TortureTimeCommander do
        commander.create_text(group_id, group_name)
      end
    end

    def create_markup
      midcall TortureTimeCommander do
        commander.create_markup
      end
    end
  end
end
