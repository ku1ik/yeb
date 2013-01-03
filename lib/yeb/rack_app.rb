require 'socket'

require 'yeb/socket_proxy'
require 'yeb/command'
require 'yeb/process'

module Yeb
  class RackApp < SocketProxy
    MAX_SPAWN_TIME = 60

    attr_reader :port

    def initialize(name, path, port)
      super(name, path)
      @port = port
    end

    def connect
      TCPSocket.new('localhost', port)
    end

    def start
      Yeb.logger.info "spawning Rack app \"#{name}\" in #{path}"

      process = Process.new(command)
      process.start

      time_left = MAX_SPAWN_TIME
      while time_left > 0 && process.alive? && !socket_ready?
        Yeb.logger.debug "waiting for port #{port} to accept connections"
        sleep 1
        time_left -= 1
      end

      if time_left == 0
        Yeb.logger.error "app \"#{name}\" hasn't exposed working socket in " \
          "#{MAX_SPAWN_TIME} seconds, killing it"
        process.stop
      end

      if socket_ready?
        Yeb.logger.debug "app \"#{name}\" is ready"
      else
        raise AppStartFailedError.new(name, path, command, process.stdout, process.stderr, env)
      end
    end

    def vhost_context
      super.merge({ :port => port })
    end

    private

    def command
      script = File.expand_path('../../../scripts/start-rack-app.sh', __FILE__)
      Command.new("#{script} #{path}", :env => { 'PORT' => port.to_s })
    end

    def env
      command = Command.new("/usr/bin/env | sort")
      process = Process.new(command)
      process.start
      (process.stdout + process.stderr).strip
    end
  end

  class AppStartFailedError < AppConnectError
    attr_reader :command, :stdout, :stderr, :env

    def initialize(app_name, path, command, stdout, stderr, env)
      super(app_name, path)
      @command = command.command
      @stdout = stdout.strip
      @stderr = stderr.strip
      @env = env
    end
  end
end
