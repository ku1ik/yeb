require 'open3'
require 'tmpdir'
require 'erb'
require 'fileutils'
require 'digest/sha1'

require 'yeb/hostname'

module Yeb
  class NGiNX
    HTTP_PORT = 30666
    HTTPS_PORT = 30667

    attr_reader :dir, :yeb_socket_path, :bin_path, :vhosts_dir, :static_assets_dir
    attr_accessor :last_vhosts_dir_digest

    def initialize(dir, yeb_socket_path)
      @dir = dir
      @yeb_socket_path = yeb_socket_path
      @bin_path = "#{dir}/sbin/nginx"
      @vhosts_dir = "#{dir}/conf/vhosts"
      @static_assets_dir = File.expand_path('../../../nginx/static', __FILE__)
    end

    def start
      unless File.exist?(bin_path)
        install
      end

      prepare_vhosts_dir
      write_config_files
      run
    end

    def run
      Yeb.logger.info "starting nginx"

      cmd = bin_path

      @thread = Thread.new do
        i, o, e, @nginx_wait_thr = Open3.popen3(cmd)
        @nginx_wait_thr.value # wait for process to finish
        Yeb.logger.error "nginx died"
      end

      @thread.abort_on_exception = true
    end

    def stop
      @thread.exit
    end

    def reload
      Yeb.logger.info 'reloading nginx'
      ::Process.kill('HUP', @nginx_wait_thr.pid)
    end

    def reload_if_needed
      current_vhosts_dir_digest = vhosts_dir_digest
      if current_vhosts_dir_digest != last_vhosts_dir_digest
        self.last_vhosts_dir_digest = current_vhosts_dir_digest
        reload
      end
    end

    def vhosts_dir_digest
      Dir["#{vhosts_dir}/*.conf"].inject('') do |acc, file|
        acc << Digest::SHA1.hexdigest(File.read(file))
        acc
      end
    end

    def install
      Yeb.logger.info 'installing nginx'

      tmp_dir = Dir.mktmpdir
      download_url = "http://nginx.org/download/nginx-1.2.6.tar.gz"

      system(
        "cd #{tmp_dir} && " \
        "wget #{download_url} && " \
        "tar xf nginx-1.2.6.tar.gz && " \
        "cd nginx-1.2.6 && " \
        "./configure --prefix=#{dir} && " \
        "make && " \
        "make install && " \
        "rm -rf #{tmp_dir}"
      )
    end

    def prepare_vhosts_dir
      Dir.mkdir(vhosts_dir) unless File.directory?(vhosts_dir)
      FileUtils.rm(Dir.glob("#{vhosts_dir}/*"))
    end

    def write_config_files
      write_config_file('default.conf')
      write_config_file('yeb.conf')
      write_config_file('_spawner.conf')
      write_config_file('nginx.conf')
    end

    def write_config_file(config_path)
      tpl = ERB.new(File.read("nginx/conf/#{config_path}.erb"))
      File.open("#{dir}/conf/#{config_path}", "w") do |f|
        f.write(tpl.result(binding))
      end
    end

    def add_vhost_file(vhost_name, app_type, context)
      Yeb.logger.debug "adding vhost for \"#{vhost_name}\""

      data = ERBTemplate.render("nginx/conf/app_types/#{app_type}.conf.erb", context)
      File.open(vhost_file_path(vhost_name), 'w') do |f|
        f.write(data)
      end
    end

    def remove_vhost_file(vhost_name)
      Yeb.logger.debug "removing vhost for \"#{vhost_name}\""

      FileUtils.rm_rf(vhost_file_path(vhost_name))
    end

    def vhost_file_path(vhost_name)
      "#{vhosts_dir}/#{vhost_name}.conf"
    end
  end
end
