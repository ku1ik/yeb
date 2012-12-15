require 'yeb/app_manager'
require 'yeb/response'
require 'yeb/template'
require 'yeb/hostname'

module Yeb
  class HTTPRequestHandler
    attr_reader :app_manager

    def initialize
      @app_manager = AppManager.new
    end

    def get_response(request)
      hostname = Hostname.from_http_request(request)
      app = app_manager.get_app_for_hostname(hostname)
      socket = app.socket
      socket.send(request, 0)
      response = socket.recv(4 * 1024 * 1024)
      socket.close
      response

    rescue AppNotFoundError => e
      Response.new do |r|
        r.status = 404
        r.body = Template.render(:app_not_found_error, {
          :app_name => e.app_name
        })
      end

    rescue AppStartFailedError => e
      Response.new do |r|
        r.status = 502
        r.body = Template.render(:app_start_failed_error, {
          :app_name => e.app_name,
          :stdout => e.stdout
        })
      end

    rescue => e
      Response.new do |r|
        r.status = 500
        r.body = Template.render(:unknown_error, { :exception => e })
      end
    end
  end
end
