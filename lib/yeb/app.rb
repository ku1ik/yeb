require 'yeb/error'

module Yeb
  class App
    attr_reader :name, :path

    def initialize(name, path)
      @name = name
      @path = path
    end

    def type
      self.class.to_s.split('::').last.gsub(/([a-z])([A-Z])/, "\\1_\\2").downcase
    end

    def call(request)
      raise NotImplementedError
    end

    def spawn
      raise NotImplementedError
    end

    def dispose
      # no op
    end

    def vhost_context
      { :path => path }
    end
  end

  class NotImplementedError < StandardError; end
end
