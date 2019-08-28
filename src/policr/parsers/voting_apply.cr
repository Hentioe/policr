module Policr
  class VotingApplyParsed
    property title, desc, note, answers

    def initialize(@title : String? = nil,
                   @desc : String? = nil,
                   @note : String? = nil,
                   @answers = Array(VotingApplyAnswerParsed).new)
    end
  end

  class VotingApplyAnswerParsed
    property name, corrected

    def initialize(@name : String, @corrected : Bool)
    end
  end

  class VotingApplyParser < Parser(VotingApplyParsed)
    @n = 0
    @lines = Array(String).new
    @last_token = VotingApplyToken::Unknown

    def_parse do
      @lines = _text.split("\n")
      process_line
    end

    def check_validity!
      missing_field! "title" unless @parsed.title
      missing_field! "desc" unless @parsed.desc
      missing_field! "note" unless @parsed.desc
      failed! "The number of answers is zero" if @parsed.answers.size == 0
      failed! "The correct number of answers is zero" if @parsed.answers.select { |a| a.corrected }.size == 0
    end

    macro append(nilable)
      ({{nilable}} || "") + "\n" + text
    end

    private def process_line
      return if @n >= @lines.size
      line = @lines[@n]
      if md = /^((-|\+)[a-z]?)(.+)/.match line
        token_s = md[1]
        text = md[3].strip
        case token_s
        when "-t"
          @parsed.title = text
          @last_token = VotingApplyToken::Title
        when "-d"
          @parsed.desc = text
          @last_token = VotingApplyToken::Desc
        when "-n"
          @parsed.note = text
          @last_token = VotingApplyToken::Note
        when "-"
          @parsed.answers << VotingApplyAnswerParsed.new(name: text, corrected: false)
          @last_token = VotingApplyToken::Answer
        when "+"
          @parsed.answers << VotingApplyAnswerParsed.new(name: text, corrected: true)
          @last_token = VotingApplyToken::Answer
        else
          normal_line text
        end
      else
        normal_line line.strip
      end
      @n += 1
      process_line
    end

    private def normal_line(text)
      case @last_token
      when VotingApplyToken::Title
        @parsed.title = append @parsed.title
      when VotingApplyToken::Desc
        @parsed.desc = append @parsed.desc
      when VotingApplyToken::Note
        @parsed.note = append @parsed.note
      end
    end
  end

  enum VotingApplyToken
    Unknown; Title; Desc; Note; Answer
  end
end
