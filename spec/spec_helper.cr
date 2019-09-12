require "spec"
require "../src/policr"

macro def_models_alias(models)
  {% for model in models %}
    alias {{model}} = Model::{{model}}
  {% end %}
end

GROUP_ID      = -123456789_i64
USER_ID       =        1234567
GROUP_TITLE_1 = "群组1"
GROUP_TITLE_2 = "群组2"

def_models_alias [
  Admin,
  Group,
  Question,
  Toggle,
  Template,
  FormatLimit,
  AntiMessage,
]
