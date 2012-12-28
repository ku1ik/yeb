require 'erb'
require 'ostruct'

module Yeb
  class ERBContext < OpenStruct
    HTML_ESCAPE = {
      '&' => '&amp;',
      '>' => '&gt;',
      '<' => '&lt;',
      '"' => '&quot;',
      "'" => '&#x27;'
    }

    def h(string)
      string.to_s.gsub(/[&"'><]/, HTML_ESCAPE)
    end
  end

  class ERBTemplate
    def self.render(_path, context = {})
      b = ERBContext.new(context).instance_eval { binding }
      template = File.read(_path)
      ERB.new(template).result(b)
    end
  end

  class Template
    def self.render(path, context = {})
      layout = ERBTemplate.render("templates/layout.erb", context)
      content = ERBTemplate.render("templates/#{path}.erb", context)

      layout.sub!('<!-- content -->', content) # cheating!
      layout.gsub!(/<!--# include file="([^"]+)" -->/) do |match|
        File.read($1)
      end

      layout

    rescue => e
      Yeb.logger.error e
      Yeb.logger.error e.backtrace.join("\n")
      'Shit.'
    end
  end
end
