module Policr
  abstract class Handler
    macro all_pass?(conditions)
      {% for condition, index in conditions %}
        {{condition}} {% if index < conditions.size - 1 %} && {% end %}
      {% end %}
    end

    macro allow_edit
      def initialize(@bot)
        super

        @allow_edit = true
      end
    end

    getter allow_edit = false
    getter bot : Bot

    def initialize(@bot)
    end

    def registry(msg, state, from_edit = false)
      if from_edit && @allow_edit
        preprocess msg, state
      elsif !from_edit
        preprocess(msg, state)
      else
        state
      end
    end

    private def preprocess(msg, state)
      if (text = msg.text) && (text.starts_with?("/")) && bot.command_names.includes?(text)
        fetch_state :done { true } # 如果是指令，直接 done => true
        return
      end
      if match(msg, state)
        handle(msg, state)
      else
        state
      end
    end

    abstract def match(msg, state : Hash(Symbol, StateValueType)) : Bool | Nil
    abstract def handle(msg, state : Hash(Symbol, StateValueType))

    macro match
      def match(msg, state)
        {{yield}}
      end
    end

    macro handle
      def handle(msg, state)
        {{yield}}
        fetch_state :done { true }
      end
    end

    macro target(type)
      {% if type == :fields %}
        @group_info : Tuple(Int64, String?)?
        @reply_msg_id : Int32?
      {% elsif type == :group %}
        target_group do {{yield}} end
      {% end %}
    end

    macro target_group
      _group_id = msg.chat.id

      if (%reply_msg = msg.reply_to_message) &&
         (%reply_msg_id = %reply_msg.message_id)
        if msg.chat.id > 0 &&
           (%menu = Model::PrivateMenu.find(msg.chat.id, %reply_msg_id)) &&
           Model::Toggle.privacy_setting?(%menu.group_id)
           _group_id = %menu.group_id
           _group_name = %menu.group_name || %menu.group_id.to_s
        end

        _reply_msg_id = %reply_msg_id
      end

      _group_info = {_group_id, _group_name}
      @group_info = _group_info

      {{yield}}
    end

    macro retrieve(conditions = [] of Any)
      if (%group_info = @group_info) && (_reply_msg_id = @reply_msg_id) &&
        {% for condition, index in conditions %}
          {{condition}} {% if index < conditions.size - 1 %} && {% end %}
        {% end %}
        _group_id, _group_name = %group_info

        {{yield}}
      end
    end

    def setting_complete_with_delay_delete(msg)
      if sended_msg = bot.reply msg, t("setting_complete")
        msg_id = sended_msg.message_id
        Schedule.after(4.seconds) { bot.delete_message msg.chat.id, msg_id }
      end
    end

    macro examine_enabled?
      fetch_state :examine_enabled { Model::Toggle.examine_enabled?(msg.chat.id) }
    end

    macro has_permission?(group_id, user_id)
      fetch_state :has_permission do 
        role = Model::Toggle.trusted_admin?({{group_id}}) ? :admin : :creator
        bot.has_permission?({{group_id}}, {{user_id}}, role)
      end
    end

    macro self_left?
      fetch_state :self_left { false }
    end
  end
end
