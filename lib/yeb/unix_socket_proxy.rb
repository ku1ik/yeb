require 'socket'

require 'yeb/socket_proxy'

module Yeb
  class UnixSocketProxy < SocketProxy

    def connect
      UNIXSocket.new(path)
    end

  end
end
