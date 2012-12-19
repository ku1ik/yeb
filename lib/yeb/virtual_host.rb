require 'pathname'
require 'digest/sha1'

module Yeb
  class VirtualHost
    attr_reader :hostname, :apps_dir, :sockets_dir

    def initialize(hostname, apps_dir, sockets_dir)
      @hostname = hostname
      @apps_dir = apps_dir
      @sockets_dir = sockets_dir
    end

    def app_symlink_path
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

    def app_real_path
      if path = app_symlink_path
        Pathname.new(path).realpath.to_s # follow all symlinks
      end
    end

    def app_name
      if path = app_symlink_path
        File.basename(path)
      end
    end

    def socket_path
      "#{sockets_dir}/#{hostname.app_name}.sock"
    end

    def app_socket_path
      if path = app_real_path
        path_hash = Digest::SHA1.hexdigest(path)
        "#{sockets_dir}/#{path_hash}.sock"
      end
    end

    def create_socket_symlink
      if app_socket_path
        if File.symlink?(socket_path) || File.exist?(socket_path)
          File.unlink(socket_path)
        end

        File.symlink(app_socket_path, socket_path)
      end
    end

    def app_symlinked?
      !!app_symlink_path
    end

    def socket
      raise AppNotFoundError.new(hostname.app_name) unless app_symlinked?

      create_socket_symlink
      spawn_app unless File.exist?(app_socket_path)

      UNIXSocket.new(socket_path)
    end

    def spawn_app
      app = RackApp.new(app_name, app_real_path, app_socket_path)
      app.spawn
    end
  end
end
