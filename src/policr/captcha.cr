module Policr
  abstract class Captcha
    getter chat_id : Int64
    getter msg_id : Int32

    def initialize(@chat_id, @msg_id)
    end

    # 生成问题/答案
    abstract def make

    macro make(proc)
      def make
        data = {{proc}}.call
        storage
        data
      end
    end

    # 返回正确答案索引
    abstract def true_index

    private def storage
      DB.storage_true_index(@chat_id, @msg_id, true_index)
    end
  end
end
