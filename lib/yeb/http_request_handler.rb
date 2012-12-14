require 'yeb/socket_manager'
require 'yeb/response'
require 'yeb/template'

module Yeb
  class HTTPRequestHandler
    attr_reader :socket_manager

    def initialize
      @socket_manager = SocketManager.new
    end

    def get_response(request)
      hostname = extract_hostname(request)
      socket = socket_manager.get_socket_for_hostname(hostname)
      socket.send(request, 0)
      response = socket.recv(4 * 1024 * 1024)
      socket.close
      response
    rescue => e
      Response.new do |r|
        r.status = 500
        r.body = Template.render(:unknown_error, { :exception => e })
      end
    end

    private

    def extract_hostname(request)
      request[/Host: ([^\n\r]+)/, 1]
    end
  end
end
