require 'erb'
require 'ostruct'

module Yeb
  class Template
    def self.render(name, context = {})
      b = OpenStruct.new(context).instance_eval { binding }

      template = File.read("templates/layout.erb")
      layout = ERB.new(template).result(b)

      template = File.read("templates/#{name}.erb")
      content = ERB.new(template).result(b)

      layout.sub!('<!-- content -->', content) # cheating!
      layout.gsub!(/<!--# include file="([^"]+)" -->/) do |match|
        File.read($1)
      end

      layout

    rescue
      'Shit.'
    end

    def self.resource_path(name)
      File.expand_path("../../../#{name}", __FILE__)
    end
  end
end
