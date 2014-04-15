module Conjoin
  class JQuery
    JS_ESCAPE = { '\\' => '\\\\', '</' => '<\/', "\r\n" => '\n', "\n" => '\n', "\r" => '\n', '"' => '\\"', "'" => "\\'" }

    attr_accessor :html, :selector, :options

    def initialize selector, options = {}
      @html     = ''
      @selector = selector
      @options  = options

      @options.empty? \
        ? @html += "$('#{selector}')" \
        : @html += "$('#{selector}', #{options.to_json})"
    end

    def method_missing(m, *args, &block)
      elem = args.first

      case elem
      when JQuery
        content = elem.to_s.chomp(';')
      when String
        content = "'#{escape elem}'"
      when Hash, OpenStruct
        content = elem.to_json
      else
        content = elem
      end

      @html += ".#{m.to_s.camelize(:lower)}(#{content})"

      self
    end

    def to_s
      return_html = html.dup.to_s
      @html       = "$('#{selector}')"
      "#{return_html};"
    end

    def escape js
      Conjoin::JQuery.escape js
    end

    def self.escape js
      js.to_s.gsub(/(\\|<\/|\r\n|\\3342\\2200\\2250|[\n\r"'])/) {|match| JS_ESCAPE[match] }
    end
  end
end
