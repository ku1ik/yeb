require 'socket'
require 'fileutils'

require 'yeb/request_handler'
require 'yeb/nginx'

module Yeb
  class Daemon
    attr_reader :socket_path, :request_handler, :nginx

    def initialize(socket_path, apps_dir)
      @socket_path = socket_path
      @request_handler = RequestHandler.new(apps_dir)
      @nginx = NGiNX.new
    end

    def start
      install_signal_handlers
      nginx.start

      FileUtils.rm(socket_path) if File.exist?(socket_path)

      socket = UNIXServer.new(socket_path)

      Socket.accept_loop(socket) do |client_socket, addr|
        puts 'got request'
        request = client_socket.recv(4096 * 1024)
        response = request_handler.handle(request).to_s
        nginx.reload
        client_socket.send(response, 0)
        client_socket.close
      end
    end

    def stop
      nginx.stop
      exit
    end

    def install_signal_handlers
      trap('INT') do
        puts 'inting'
        stop
        puts 'inted'
      end

      trap('TERM') do
        puts 'terming'
        stop
        puts 'termed'
      end

      trap('QUIT') do
        puts 'quitting'
        stop
        puts 'quited'
      end

      # trap("HUP") { handle_hup }
    end
  end
end
