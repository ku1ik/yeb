require 'yeb/app_manager'

module Yeb
  class SocketManager

    attr_reader :app_manager

    def initialize
      @app_manager = AppManager.new
    end

    def get_socket_for_hostname(hostname)
      root_hostname = extract_root_hostname(hostname)

      unless socket_exists_for_hostname?(root_hostname)
        spawn_app(root_hostname)
      end

      if hostname != root_hostname
        unless socket_exists_for_hostname?(hostname)
          symlink(root_hostname, hostname)
        end
      end

      UNIXSocket.new(socket_path_for_hostname(hostname))
    end

    private

    def extract_root_hostname(hostname)
      hostname[/(.+\.)?([^\.]+\.dev)$/, 2]
    end

    def socket_exists_for_hostname?(hostname)
      File.exist?(socket_path_for_hostname(hostname))
    end

    def socket_path_for_hostname(hostname)
      "#{SOCKETS_DIR}/#{hostname}.sock"
    end

    def spawn_app(hostname)
      puts "spawning app for #{hostname}"
      app_name = hostname[/^(.+)\.dev$/, 1]
      socket_path = socket_path_for_hostname(hostname)
      app_manager.spawn_app(app_name, socket_path)
    end

    def symlink(root_hostname, hostname)
      src = socket_path_for_hostname(root_hostname)
      dst = socket_path_for_hostname(hostname)
      FileUtils.rm(dst) if File.symlink?(dst)
      File.symlink(src, dst)
    end
  end
end
