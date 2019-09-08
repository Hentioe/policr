module Policr
  class WelcomeContentParsed
    property content, buttons

    def initialize(@content : String? = nil,
                   @buttons = Array(WelcomeButtonParsed).new)
    end
  end

  class WelcomeButtonParsed
    property text, link

    def initialize(@text : String, @link : String)
    end
  end

  class WelcomeContentParser < Parser(WelcomeContentParsed)
    @n = 0
    @lines = Array(String).new

    def_parse do
      @lines = _text.split("\n")
      process_line
    end

    def check_validity!
      missing_field! "content" unless @parsed.content
    end

    RE_MARKDOWN_LINK = /^\[(.+)\]\((.+)\)/
    RE_STARTS_FLAG   = /^((-|\+)[a-z]?)(.+)/

    private def process_line
      return if @n >= @lines.size
      line = @lines[@n]
      if md = RE_STARTS_FLAG.match line
        token_s = md[1]
        text = md[3].strip
        case token_s
        when "-b"
          if ml_md = RE_MARKDOWN_LINK.match text
            text = ml_md[1].strip
            link = ml_md[2].strip
            @parsed.buttons << WelcomeButtonParsed.new(text: text, link: link)
          else
            normal_line text
          end
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
        if content = @parsed.content
          content += "\n" + line
        else
          line
        end
      @parsed.content = line
    end
  end
end
