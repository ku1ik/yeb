require 'yeb/hostname'
require 'yeb/app_manager'
require 'yeb/response'
require 'yeb/template'

module Yeb
  class RequestHandler
    attr_reader :app_manager

    def initialize(apps_dir)
      @app_manager = AppManager.new(apps_dir)
    end

    def handle(request)
      hostname = Hostname.from_http_request(request)
      app = app_manager.get_app(hostname)
      app.write_vhost_file(hostname)
      return app.handle(request)

    rescue AppNotFoundError => e
      Response.new do |r|
        r.status = 404
        r.body = Template.render(:app_not_found_error, {
          :app_name => e.app_name
        })
      end

    rescue AppNotRecognizedError => e
      Response.new do |r|
        r.status = 404
        r.body = Template.render(:app_not_recognized_error, {
          :app_name => e.app_name
        })
      end

    rescue AppStartFailedError => e
      Response.new do |r|
        r.status = 502
        r.body = Template.render(:app_start_failed_error, {
          :app_name => e.app_name,
          :stdout => e.stdout,
          :stderr => e.stderr,
          :env => e.env
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
