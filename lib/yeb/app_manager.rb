require 'yeb/rack_app'
require 'yeb/error'
require 'pathname'

module Yeb
  class AppManager
    attr_reader :apps_dir, :apps

    def initialize(apps_dir)
      @apps_dir = apps_dir
      @apps = {}
      @port = 20000
    end

    def get_app(hostname)
      if name = get_app_name(hostname)
        unless apps[name]
          path = get_app_symlink_path(hostname)
          apps[name] = create_app(name, path)
        end

        apps[name]
      else
        raise AppNotFoundError.new(hostname.app_name)
      end
    end

    def create_app(name, path)
      real_path = Pathname.new(path).realpath.to_s

      if File.directory?(real_path)
        if File.exist?("#{real_path}/config.ru")
          app = RackApp.new(name, real_path, next_available_port)
        else
          raise AppNotRecognizedError.new(name, path)
        end

      elsif File.socket?(real_path)
        app = UnixSocketProxy.new(name, real_path)

      elsif File.file?(real_path)
        upstream = File.read(real_path).strip

        if upstream =~ /^\d+$/
          port = upstream.to_i
          app = TcpSocketProxy.new(name, real_path, port)
        else
          raise AppNotRecognizedError.new(name, path)
        end

      else
        raise AppNotRecognizedError.new(name, path)
      end

      app.spawn
      app
    end

    def get_app_name(hostname)
      if path = get_app_symlink_path(hostname)
        File.basename(path)
      end
    end

    def get_app_symlink_path(hostname)
      symlinked_app_dir = "#{apps_dir}/#{hostname.app_name}"

      if File.symlink?(symlinked_app_dir)
        return symlinked_app_dir
      end

      if hostname != hostname.root
        symlinked_app_dir = "#{apps_dir}/#{hostname.root.app_name}"

        if File.symlink?(symlinked_app_dir)
          return symlinked_app_dir
        end
      end

      nil
    end

    def next_available_port
      port = @port
      @port += 1
      port
    end
  end

  class AppNotFoundError < Error; end
  class AppNotRecognizedError < Error; end
end
