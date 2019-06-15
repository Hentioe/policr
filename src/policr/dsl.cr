macro midcall(cls)
  %k = ""
  {% for c, index in cls.stringify.chars %}
    {% if index != 0 && c.stringify =~ /[A-Z]/ %}
      %k += "_" + {{c}}
    {% else %}
      %k += {{c}}
    {% end %}
  {% end %}
  %k = %k.downcase.gsub(/(_handler|_commander|_callback)/, "")
  {{ cls_name = cls.stringify }}
  {% if cls_name.ends_with?("Handler") %}
    if (handler = bot.handlers[%k]?) && (handler.is_a?({{cls}}))
      {{yield}}
    end
  {% elsif cls_name.ends_with?("Commander") %}
    if (commander = bot.commanders[%k]?) && (commander.is_a?({{cls}}))
      {{yield}}
    end
  {% elsif cls_name.ends_with?("Callback") %}
    if (callback = bot.callbacks[%k]?) && (callback.is_a?({{cls}}))
      {{yield}}
    end
  {% end %}
end
