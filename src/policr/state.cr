alias StateValueType = Bool | Int32

STATE_TYPE_MAP = {
  :done            => Bool,
  :self_left       => Bool,
  :examine_enabled => Bool,
}

macro fetch_state(name)
  {{ cls = STATE_TYPE_MAP[name] }}
  if (val = state[{{name}}]?) && (val.is_a?({{cls}}))
    val
  else
    bot.debug "Setting state {{name}} in " + {{ @type.stringify }}
    val = {{yield}}
    state[{{name}}] = val

    val
  end
end

macro examine_enabled?(chat_id)
  fetch_state :examine_enabled { KVStore.enabled_examine?({{chat_id}}) }
end
