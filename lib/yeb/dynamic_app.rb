require 'socket'

require 'yeb/socket_proxy'
require 'yeb/process'

module Yeb
  class DynamicApp < SocketProxy
    MAX_SPAWN_TIME = 60
    RUNNER_SCRIPT = File.expand_path('../../../scripts/runner.sh', __FILE__)

    attr_reader :port

    def initialize(name, path, port)
      super(name, path)
      @port = port
    end

    def connect
      TCPSocket.new('localhost', port)
    end

    def start
      Yeb.logger.info "spawning app \"#{name}\" in #{path}"

      env = { 'DIR' => path, 'PORT' => port.to_s }
      command = "#{path}/.yebrc"
      @process = Process.new(RUNNER_SCRIPT, env)
      @process.start

      time_left = MAX_SPAWN_TIME
      while time_left > 0 && @process.alive? && !socket_ready?
        Yeb.logger.debug "waiting for port #{port} to accept connections"
        sleep 1
        time_left -= 1
      end

      if time_left == 0
        Yeb.logger.error "app \"#{name}\" hasn't exposed working socket in " \
          "#{MAX_SPAWN_TIME} seconds, killing it"
        @process.stop
      end

      if socket_ready?
        Yeb.logger.debug "app \"#{name}\" is ready"
      else
        raise DynamicAppStartFailedError.new(name, path, @process.stdout, @process.stderr)
      end
    end

    def dispose
      Yeb.logger.info "killing app \"#{name}\""
      @process.stop
    end

    def restart_requested?
      File.exist?("#{path}/tmp/restart.txt")
    end

    def clean_restart_request_state
      FileUtils.rm_rf("#{path}/tmp/restart.txt")
    end

    def vhost_context
      super.merge({ :port => port })
    end
  end

  class DynamicAppStartFailedError < AppConnectError
    attr_reader :stdout, :stderr

    def initialize(app_name, path, stdout, stderr)
      super(app_name, path)
      @stdout = stdout.strip
      @stderr = stderr.strip
    end
  end
end
