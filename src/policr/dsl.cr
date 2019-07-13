macro midcall(cls)
  {{ cls_name = cls.stringify }}
  {{ key = cls_name.underscore.gsub(/(_handler|_commander|_callback)/, "") }}
  {% if cls_name.ends_with?("Handler") %}
    if (handler = bot.handlers[{{key}}]?) && (handler.is_a?({{cls}}))
      {{yield}}
    end
  {% elsif cls_name.ends_with?("Commander") %}
    if (commander = bot.commanders[{{key}}]?) && (commander.is_a?({{cls}})) && (_commander = commander)
      {{yield}}
    end
  {% elsif cls_name.ends_with?("Callback") %}
    if (callback = bot.callbacks[{{key}}]?) && (callback.is_a?({{cls}})) && (_callback = callback)
      {{yield}}
    end
  {% end %}
end
