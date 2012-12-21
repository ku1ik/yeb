require 'yeb/error'

module Yeb
  class App
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def handle(request)
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

    def connect
      raise NotImplementedError
    end

    def spawn
      raise NotImplementedError
    end

    def write_vhost_file(hostname)
      raise NotImplementedError
    end
  end

  class NotImplementedError < Error; end
end
