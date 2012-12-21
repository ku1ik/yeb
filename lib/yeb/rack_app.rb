require 'yeb/app'
require 'yeb/command'
require 'yeb/process'
require 'yeb/template'
require 'yeb/error'

module Yeb
  class RackApp < App
    attr_reader :path, :port

    def initialize(name, path, port)
      super(name)
      @path = path
      @port = port
    end

    def connect
      TCPSocket.new('localhost', port)
    end

    def spawn
      puts "Spawning Rack app #{name} in #{path}"

      process = Process.new(command)
      process.start

      while process.alive? && !socket_ready?
        puts "waiting for port #{port} to accept connections"
        sleep 1
      end

      unless socket_ready?
        raise AppStartFailedError.new(name, process.stdout, process.stderr, env)
      end
    end

    def command
      Command.new("#{thin} start -p #{port}", path)
    end

    def thin
      path = `which thin`.strip

      if path == ''
        raise 'nie ma thina'
      end

      path
    end

    def env
      command = Command.new("/usr/bin/env | sort")
      process = Process.new(command)
      process.start
      process.stdout + process.stderr
    end

    def write_vhost_file(hostname)
      context = {
        :app_name => name,
        :hostname => hostname.to_s,
        :port => port
      }

      data = ERBTemplate.render('nginx/conf/forwarded-site.conf.erb', context)

      File.open("#{VHOSTS_DIR}/#{name}.conf", 'w') do |f|
        f.write(data)
      end
    end
  end

  class AppStartFailedError < Error
    attr_reader :stdout, :stderr, :env

    def initialize(app_name, stdout, stderr, env)
      super(app_name)
      @stdout = stdout
      @stderr = stderr
      @env = env
    end
  end
end
