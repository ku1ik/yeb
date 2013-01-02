require 'yeb/app'

module Yeb
  class SocketProxy < App

    def call(request)
      socket = connect
      socket.send(request.string, 0)

      response = ''
      while (s = socket.recv(4 * 1024)).size > 0
        response << s
      end

      socket.close
      response
    end

    def socket_ready?
      socket = connect
      socket.close
      true
    rescue Errno::ECONNREFUSED, Errno::ENOENT
      false
    end

    alias alive? socket_ready?

    def connect
      raise NotImplementedError
    end
  end

  class AppConnectError < AppError
    def template_name
      self.class.to_s.split('::').last.gsub(/([a-z])([A-Z])/, "\\1_\\2").downcase
    end
  end
end
