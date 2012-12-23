require 'open3'
require 'tmpdir'
require 'erb'
require 'fileutils'

require 'yeb/hostname'

module Yeb
  class NGiNX
    def initialize
    end

    def start
      unless File.exist?("#{NGINX_PREFIX}/sbin/nginx")
        install
      end

      prepare_vhosts_dir
      write_configs
      run
    end

    def run
      cmd = NGINX_BIN

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
        "./configure --prefix=#{NGINX_PREFIX} && " \
        "make && " \
        "make install && " \
        "rm -rf #{tmp_dir}"
      )
    end

    def prepare_vhosts_dir
      Dir.mkdir(VHOSTS_DIR) unless File.directory?(VHOSTS_DIR)
      FileUtils.rm Dir.glob("#{VHOSTS_DIR}/*")
    end

    def write_configs
      tpl = ERB.new(File.read('nginx/conf/default-site.conf.erb'))
      File.open("#{NGINX_PREFIX}/conf/default-site.conf", "w") do |f|
        f.write(tpl.result)
      end

      tpl = ERB.new(File.read('nginx/conf/dynamic-site.conf.erb'))
      File.open("#{NGINX_PREFIX}/conf/dynamic-site.conf", "w") do |f|
        f.write(tpl.result)
      end

      tpl = ERB.new(File.read('nginx/conf/nginx.conf.erb'))
      File.open("#{NGINX_PREFIX}/conf/nginx.conf", "w") do |f|
        f.write(tpl.result)
      end
    end
  end
end
