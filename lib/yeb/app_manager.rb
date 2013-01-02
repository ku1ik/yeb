require 'yeb/rack_app'
require 'yeb/tcp_socket_proxy'
require 'yeb/unix_socket_proxy'
require 'yeb/static_site'
require 'yeb/error'
require 'pathname'

module Yeb
  class AppManager
    attr_reader :apps_dir, :apps, :next_available_port

    def initialize(apps_dir)
      @apps_dir = apps_dir
      @apps = {}
      @next_available_port = 20000
    end

    def get_app(hostname)
      if name = get_app_name(hostname)
        if app = apps[name]
          # probably it's dead or socket not responding
          unless app.alive?
            Yeb.logger.info "removing dead app \"#{name}\""
            app.dispose
            apps.delete(name)
          end
        end

        unless apps[name]
          Yeb.logger.info "creating new app \"#{name}\""
          path = get_app_path(hostname)
          apps[name] = create_app(name, path)
        end

        apps[name]
      else
        raise AppNotFoundError.new(hostname.app_name)
      end
    end

    def create_app(name, path)
      begin
        real_path = Pathname.new(path).realpath.to_s
      rescue Errno::ENOENT
        raise AppSymlinkInvalidError.new(name, path)
      end

      if File.directory?(real_path)
        if File.exist?("#{real_path}/config.ru")
          app = RackApp.new(name, real_path, next_available_port)
          app.start
          @next_available_port += 1
        elsif File.exist?("#{real_path}/index.html")
          app = StaticSite.new(name, real_path)
        else
          raise AppNotRecognizedError.new(name, path)
        end

      elsif File.socket?(real_path)
        app = UnixSocketProxy.new(name, real_path)
        app.start

      elsif File.file?(real_path)
        upstream = File.read(real_path).strip

        if upstream =~ /^[a-z0-9:.-]+$/
          if upstream =~ /^\d+$/
            host = 'localhost'
            port = upstream.to_i
          elsif upstream =~ /^([\w-]+\.?)+(:\d+)?$/
            host, port = upstream.split(':')
            port ||= 80
          else
            raise 'Bad tcp proxy endpoint format'
          end

          app = TcpSocketProxy.new(name, real_path, host, port)
          app.start
        else
          raise AppNotRecognizedError.new(name, path)
        end

      else
        raise AppNotRecognizedError.new(name, path)
      end

      app
    end

    def get_app_name(hostname)
      if path = get_app_path(hostname)
        File.basename(path)
      end
    end

    def get_app_path(hostname)
      app_path = "#{apps_dir}/#{hostname.app_name}"

      if File.exist?(app_path) || File.symlink?(app_path)
        return app_path
      end

      if hostname != hostname.root
        app_path = "#{apps_dir}/#{hostname.root.app_name}"

        if File.exist?(app_path) || File.symlink?(app_path)
          return app_path
        end
      end

      nil
    end
  end

  class AppNotFoundError < Error; end
  class AppNotRecognizedError < AppError; end
  class AppSymlinkInvalidError < AppError; end
end
