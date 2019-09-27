require "rule_engine"

module Policr
  class BlockContentParsed
    property alias_s, rule

    def initialize(@alias_s : String? = nil,
                   @rule : String? = nil)
    end
  end

  class BlockContentParser < Parser(BlockContentParsed)
    @n = 0
    @lines = Array(String).new

    def_parse do
      @lines = _text.split("\n")
      process_line
    end

    def check_validity!
      missing_field! "alias" unless @parsed.alias_s
      missing_field! "rule" unless @parsed.rule
      RuleEngine.compile! @parsed.rule.not_nil!
    end

    RE_STARTS_FLAG = /^((-|\+)[a-z]?)(.+)/

    private def process_line
      return if @n >= @lines.size
      line = @lines[@n]
      if md = RE_STARTS_FLAG.match line
        token_s = md[1]
        text = md[3].strip
        case token_s
        when "-a"
          @parsed.alias_s = text
        else
          normal_line text
        end
      else
        normal_line line.strip
      end
      @n += 1
      process_line
    end

    private def normal_line(line)
      line =
        if content = @parsed.rule
          content += "\n" + line
        else
          line
        end
      @parsed.rule = line
    end
  end
end
