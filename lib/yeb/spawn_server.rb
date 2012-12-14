require 'socket'
require 'yeb/http_request_handler'

module Yeb
  class SpawnServer
    def initialize(socket_path)
      @socket_path = socket_path
      @request_handler = HTTPRequestHandler.new
    end

    def listen
      FileUtils.rm(@socket_path) if File.exist?(@socket_path)

      socket = UNIXServer.new(@socket_path)

      Socket.accept_loop(socket) do |client_socket, addr|
        puts 'got request'
        request = client_socket.recv(4096 * 1024)
        response = @request_handler.get_response(request).to_s
        client_socket.send(response, 0)
        client_socket.close
      end
    end
  end
end