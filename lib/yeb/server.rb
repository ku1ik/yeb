require 'socket'
require 'fileutils'

require 'yeb/version'
require 'yeb/logger'
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
      Yeb.logger.info "starting Yeb v#{VERSION}"
      setup_signal_handlers

      if nginx.start
        listen
      else
        exit 1
      end
    end

    def listen
      FileUtils.rm(socket_path) if File.exist?(socket_path)
      socket = UNIXServer.new(socket_path)

      Socket.accept_loop(socket) do |client_socket, addr|
        handle(client_socket)
      end
    end

    def handle(client_socket)
      response = nil
      request = client_socket.recv(4096 * 1024)
      hostname = Hostname.from_http_request(request)
      Yeb.logger.info "got request for #{hostname}"
      remove_nginx_vhost(hostname)
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

    rescue AppSymlinkInvalidError => e
      response = Response.new do |r|
        r.status = 502
        r.body = Template.render(:app_symlink_invalid_error, {
          :app_name => e.app_name,
          :path => e.path
        })
      end

    rescue AppConnectError => e
      response = Response.new do |r|
        r.status = 502
        r.body = Template.render(e.template_name, {
          :app_name => e.app_name,
          :path => e.path,
          :exception => e
        })
      end

    rescue => e
      response = Response.new do |r|
        r.status = 500
        r.body = Template.render(:unknown_error, { :exception => e })
      end

    ensure
      nginx.reload_if_needed

      begin
        client_socket.send(response.to_s, 0)
      rescue Errno::EPIPE => e
      end

      client_socket.close
    end

    def add_nginx_vhost(hostname, app)
      context = {
        :app_name => app.name,
        :server_name => hostname.to_nginx_server_name,
        :apps_dir => apps_dir
      }

      context.merge!(app.vhost_context)

      nginx.add_vhost_file(hostname.app_name, app.type, context)
    end

    def remove_nginx_vhost(hostname)
      nginx.remove_vhost_file(hostname.app_name)
    end

    def stop
      nginx.stop
      exit
    end

    def setup_signal_handlers
      trap('INT') do
        puts 'inting'
        stop
      end

      trap('TERM') do
        puts 'terming'
        stop
      end

      trap('QUIT') do
        puts 'quitting'
        stop
      end

      # trap("HUP") { handle_hup }
    end
  end
end
