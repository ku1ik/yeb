require 'socket'
require 'fileutils'

require 'yeb/app_manager'
require 'yeb/nginx'
require 'yeb/hostname'
require 'yeb/response'
require 'yeb/template'

module Yeb
  class Server
    attr_reader :socket_path, :apps_dir, :app_manager, :nginx

    def initialize(dir)
      @socket_path = "#{dir}/._.sock"
      @apps_dir = dir
      @app_manager = AppManager.new(apps_dir)
      @nginx = NGiNX.new("#{dir}/.nginx", socket_path)
    end

    def start
      setup_signal_handlers
      nginx.start
      listen
    end

    def listen
      FileUtils.rm(socket_path) if File.exist?(socket_path)
      socket = UNIXServer.new(socket_path)

      Socket.accept_loop(socket) do |client_socket, addr|
        puts 'got request'
        handle(client_socket)
      end
    end

    def handle(client_socket)
      response = nil
      request = client_socket.recv(4096 * 1024)
      hostname = Hostname.from_http_request(request)
      app = app_manager.get_app(hostname)
      response = app.call(request)
      add_nginx_vhost(hostname, app)

    rescue AppNotFoundError => e
      response = Response.new do |r|
        r.status = 404
        r.body = Template.render(:app_not_found_error, {
          :app_name => e.app_name
        })
      end

    rescue AppNotRecognizedError => e
      response = Response.new do |r|
        r.status = 404
        r.body = Template.render(:app_not_recognized_error, {
          :app_name => e.app_name,
          :path => e.path
        })
      end

    rescue AppStartFailedError => e
      response = Response.new do |r|
        r.status = 502
        r.body = Template.render(:app_start_failed_error, {
          :app_name => e.app_name,
          :stdout => e.stdout,
          :stderr => e.stderr,
          :env => e.env
        })
      end

    rescue => e
      response = Response.new do |r|
        r.status = 500
        r.body = Template.render(:unknown_error, { :exception => e })
      end

    ensure
      client_socket.send(response.to_s, 0)
      client_socket.close
    end

    def add_nginx_vhost(hostname, app)
      context = {
        :app_name => app.name,
        :hostname => hostname.to_s,
        :apps_dir => apps_dir
      }

      context.merge!(app.vhost_context)

      nginx.write_vhost_file(app.type, hostname.app_name, context)
      nginx.reload
    end

    def stop
      nginx.stop
      exit
    end

    def setup_signal_handlers
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
