require 'socket'

require 'yeb/app'

module Yeb
  class TcpSocketProxy < App
    attr_reader :path, :host, :port

    def initialize(name, path, host, port)
      super(name)
      @path = path
      @host = host
      @port = port
    end

    def connect
      TCPSocket.new(host, port)
    end

    def spawn
      unless socket_ready?
        raise TcpProxyConnectError.new(name, path, host, port)
      end
    end

    def vhost_context
      super.merge({ :host => host, :port => port })
    end
  end

  class TcpProxyConnectError < AppConnectError
    attr_reader :host, :port

    def initialize(app_name, path, host, port)
      super(app_name, path)
      @host = host
      @port = port
    end
  end
end
