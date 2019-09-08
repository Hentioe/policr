module Policr
  abstract class Parser(T)
    @parsed : T = T.new

    abstract def parse!(text : String) : T

    abstract def check_validity!

    macro def_parse
      def parse!(_text) : T
        {{yield}}
        check_validity!
        @parsed
      end

      def self.parse!(text)
        instance = {{@type}}.allocate
        instance.initialize
        instance.parse! text
      end

      def self.parse(text)
        begin 
          parse! text
        rescue e : Exception
          nil
        end
      end
    end

    def missing_field!(name)
      raise Exception.new "Parsing failed, missing #{name} field"
    end

    def failed!(reason)
      raise Exception.new reason
    end
  end
end
