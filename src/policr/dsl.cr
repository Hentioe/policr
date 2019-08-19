macro midcall(cls)
  {{ cls_name = cls.stringify }}
  {{ key = cls_name.underscore.gsub(/(_handler|_commander|_callbacker)/, "") }}
  {% if cls_name.ends_with?("Handler") %}
    if (handler = bot.handlers[{{key}}]?) && (handler.is_a?({{cls}})) && (_handler = handler)
      {{yield}}
    end
  {% elsif cls_name.ends_with?("Commander") %}
    if (commander = bot.commanders[{{key}}]?) && (commander.is_a?({{cls}})) && (_commander = commander)
      {{yield}}
    end
  {% elsif cls_name.ends_with?("Callbacker") %}
    if (_callbacker = bot.callbackers[{{key}}]?) && _callbacker.is_a?({{cls}})
      {{yield}}
    end
  {% end %}
end

macro midreg(cls)
  {{ cls_name = cls.stringify }}
  {{ key = cls_name.underscore.gsub(/(_handler|_commander|_callbacker)/, "") }}
  %mid =
  {% if cls_name.ends_with?("Handler") %}
    handlers
  {% elsif cls_name.ends_with?("Commander") %}
    commanders
    command_names << "/{{key.id}}"
    command_names << "/{{key.id}}@#{username}"
  {% elsif cls_name.ends_with?("Callbacker") %}
    callbackers
  {% end %}
  %mid[{{key}}] = {{cls}}.new self
end

macro escape_all(text,
                 symbol,
                 chars = [] of String)
  {{text}}{% for char in chars %}
    .gsub({{char}}, "{{symbol.id}}{{char.id}}")
  {% end %}
end

macro gen_locale(group_id)
  if lang = Model::Language.find({{group_id}})
    case LanguageCode.new(lang.code)
    when LanguageCode::ZhHans
      "zh-hans"
    when LanguageCode::ZhHant
      "zh-hant"
    when LanguageCode::English
      "english"
    else
      "zh-hans"
    end
  else
    "zh-hans"
  end
end

macro wrapper_title(text)
  if group_name
    "__From #{group_name}__\n\n#{{{text}}}"
  else
    {{text}}
  end
end

macro commander(name)
  class {{name}}Commander < Commander
    match :{{name.stringify.underscore}}

    {{yield}}

  end
end

macro callbacker(name)
  class {{name}}Callbacker < Callbacker
    match :{{name.stringify}}

    {{yield}}

  end
end

macro handler(name)
  class {{name}}Handler < Handler

    {{yield}}

  end
end
