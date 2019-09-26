alias StateValueType = Bool

STATE_TYPE_MAP = {
  :done               => Bool,
  :deleted            => Bool,
  :self_left          => Bool,
  :examine_enabled    => Bool,
  :has_permission     => Bool,
  :anti_halal_enabled => Bool,
}

macro fetch_state(name)
  {{ cls = STATE_TYPE_MAP[name] }}
  val = state[{{name}}]?
  if val != nil && (val.is_a?({{cls}}))
    bot.debug "Getting state {{name}} => #{val} in " + {{ @type.stringify }}
    
    val
  else
    val = {{yield}}
    bot.debug "Setting state {{name}} => #{val} in " + {{ @type.stringify }}
    state[{{name}}] = val

    val
  end
end

macro update_state(name)
  val = {{yield}}
  {{ cls = STATE_TYPE_MAP[name] }}
  bot.debug "Updating state {{name}} => #{val} in " + {{ @type.stringify }}
  state[{{name}}] = val

  val
end
