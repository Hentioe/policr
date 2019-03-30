module Policr
  class TortureData
    include JSON::Serializable

    property source_text = "UNDEFINED"
    property choose_text = "UNDEFINED"
    property target_user = 0_i32

    def initialize(@source_text, @choose_text, @target_user)
    end
  end
end
