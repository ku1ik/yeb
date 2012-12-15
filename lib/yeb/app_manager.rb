module Yeb
  class AppManager

    def initialize
      @apps = {}
    end

    def get_app_for_hostname(hostname)
      app_name = App.name_from_hostname(hostname)

      if app_symlinked?(app_name)
        spawn_app(app_name, hostname)
      else
        shutdown_app(app_name)
        raise AppNotFoundError.new(app_name)
      end
    end

    private

    def app_symlinked?(app_name)
      File.symlink?(app_path(app_name))
    end

    def spawn_app(app_name, hostname)
      app = @apps[app_name]

      if app.nil?
        dir = app_path(app_name)
        socket_path = socket_path_for_hostname(hostname)
        app = App.new(app_name, dir, socket_path)
        @apps[app_name] = app
      end

      app.spawn

      app
    end

    def shutdown_app(app_name)
      if app = @apps[app_name]
        app.shutdown
        @apps.delete(app_name)
      end
    end

    def app_path(app_name)
      "#{APPS_DIR}/#{app_name}"
    end

    def socket_path_for_hostname(hostname)
      "#{SOCKETS_DIR}/#{hostname.root}.sock"
    end
  end
end
