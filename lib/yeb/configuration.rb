module Yeb
  module Cfg
    extend self

    def prepare
      Dir.mkdir(main_dir) unless File.directory?(main_dir)
      Dir.mkdir(apps_dir) unless File.directory?(apps_dir)
      Dir.mkdir(sockets_dir) unless File.directory?(sockets_dir)
    end

    def nginx_static_assets
      File.expand_path('../../../nginx/static', __FILE__)
    end

    def vhosts_dir
      "#{main_dir}/.vhosts"
    end

    def apps_dir
      main_dir
    end

    def daemon_socket_path
      "#{sockets_dir}/_.sock"
    end

    def http_port
      30666
    end

    def https_port
      30667
    end
  end
end
