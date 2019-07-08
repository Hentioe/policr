module Policr
  abstract class Verification
    getter chat_id : Int64

    def initialize(@chat_id)
    end

    # 生成问题/答案
    abstract def make

    macro make
      def make
        data = {{yield}}
        data
      end
    end

    # 返回正确答案索引
    abstract def indeces

    def storage(msg_id)
      Model::TrueIndex.add(@chat_id, msg_id, indeces)
    end
  end
end
