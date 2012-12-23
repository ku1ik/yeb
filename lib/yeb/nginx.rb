require 'open3'
require 'tmpdir'
require 'erb'
require 'fileutils'

require 'yeb/hostname'

module Yeb
  class NGiNX
    attr_reader :dir, :yeb_socket_path, :bin_path, :vhosts_dir, :static_assets_dir

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
      cmd = bin_path

      @thread = Thread.new do
        loop do
          Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
            pid = wait_thr.pid # pid of the started process.
            exit_status = wait_thr.value # Process::Status object returned.
            puts "exited: #{cmd}"
            puts stdout.read
            puts stderr.read
          end

          puts 'nginx died'
          sleep 1
        end
      end

      @thread.abort_on_exception = true
    end

    def stop
      @thread.exit
    end

    def reload

    end

    def install
      puts 'installing nginx'

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

    def write_vhost_file(app_type, vhost_name, context)
      data = ERBTemplate.render("nginx/conf/app_types/#{app_type}.conf.erb", context)

      File.open("#{vhosts_dir}/#{vhost_name}.conf", 'w') do |f|
        f.write(data)
      end
    end
  end
end
