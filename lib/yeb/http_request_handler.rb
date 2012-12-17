module Yeb
  class HTTPRequestHandler
    attr_reader :apps_dir, :sockets_dir

    def initialize(apps_dir, sockets_dir)
      @apps_dir = apps_dir
      @sockets_dir = sockets_dir
    end

    def get_response(request)
      hostname = Hostname.from_http_request(request)
      vhost = VirtualHost.new(hostname, apps_dir, sockets_dir)
      socket = vhost.socket
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
