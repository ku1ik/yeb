require 'yeb/app'

module Yeb
  class AppManager
    def initialize
      @apps = {}
    end

    def spawn_app(app_name, socket_path)
      dir = "#{APPS_DIR}/#{app_name}"
      app = @apps[app_name] ||= App.new(app_name)
      app.spawn(dir, socket_path)
    end
  end
end
