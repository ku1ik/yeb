require 'yeb/error'

module Yeb
  class App
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def call(request)
      socket = connect
      socket.send(request, 0)
      response = socket.recv(4 * 1024 * 1024)
      socket.close
      response
    end

    def socket_ready?
      socket = connect
      socket.close
      true
    rescue Errno::ECONNREFUSED
      false
    end

    alias :alive? :socket_ready?

    def type
      self.class.to_s.split('::').last.gsub(/([a-z])([A-Z])/, "\\1_\\2").downcase
    end

    def connect
      raise NotImplementedError
    end

    def spawn
      raise NotImplementedError
    end

    def dispose
      raise NotImplementedError
    end

    def vhost_context
      raise NotImplementedError
    end
  end

  class NotImplementedError < Error; end
end
