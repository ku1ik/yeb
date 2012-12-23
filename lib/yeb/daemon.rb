require 'socket'

require 'yeb/request_handler'

module Yeb
  class Daemon
    attr_reader :request_handler

    def initialize(socket_path, apps_dir)
      @socket_path = socket_path
      @request_handler = RequestHandler.new(apps_dir)
    end

    def run
      FileUtils.rm(@socket_path) if File.exist?(@socket_path)

      socket = UNIXServer.new(@socket_path)

      Socket.accept_loop(socket) do |client_socket, addr|
        puts 'got request'
        request = client_socket.recv(4096 * 1024)
        response = request_handler.handle(request).to_s
        client_socket.send(response, 0)
        client_socket.close
      end
    end
  end
end
