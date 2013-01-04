require 'socket'
require 'fileutils'
require 'stringio'

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
      request = StringIO.new(client_socket.recv(4096 * 1024))
      hostname = Hostname.from_http_request(request.string)
      Yeb.logger.info "got request for #{hostname}"
      remove_nginx_vhost(hostname)
      app = app_manager.get_app(hostname)
      response = app.call(request)
      add_nginx_vhost(hostname, app)

    rescue AppNotFoundError => e
      body = Template.render(:app_not_found_error, {
        :app_name => e.app_name
      })

      response = [404, body]

    rescue AppNotRecognizedError => e
      body = Template.render(:app_not_recognized_error, {
        :app_name => e.app_name,
        :path => e.path
      })

      response = [404, body]

    rescue AppSymlinkInvalidError => e
      body = Template.render(:app_symlink_invalid_error, {
        :app_name => e.app_name,
        :path => e.path
      })

      response = [502, body]

    rescue AppConnectError => e
      body = Template.render(e.template_name, {
        :app_name => e.app_name,
        :path => e.path,
        :exception => e
      })

      response = [502, body]

    rescue => e
      body = Template.render(:unknown_error, { :exception => e })
      response = [500, body]

    ensure
      nginx.reload_if_needed

      begin
        if response.is_a?(Array)
          response_text = Response.new do |r|
            r.status = response[0]
            r.body = response[1]
          end.to_s
        else
          response_text = response.to_s
        end

        client_socket.send(response_text, 0)

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

    def setup_signal_handlers
      trap 'INT' do
        ::Process.kill 'TERM', $$
      end

      at_exit do
        Yeb.logger.info 'shutting down...'
        ::Process.kill 'TERM', -::Process.getpgrp # terminate all the children
      end
    end
  end
end
