alias StateValueType = Bool

STATE_TYPE_MAP = {
  :done            => Bool,
  :self_left       => Bool,
  :examine_enabled => Bool,
  :has_permission  => Bool,
}

macro fetch_state(name)
  {{ cls = STATE_TYPE_MAP[name] }}
  if (val = state[{{name}}]? != nil) && (val.is_a?({{cls}}))
    val
  else
    val = {{yield}}
    bot.debug "Setting state {{name}} => #{val} in " + {{ @type.stringify }}
    state[{{name}}] = val

    val
  end
end
