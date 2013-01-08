require 'socket'

require 'yeb/socket_proxy'
require 'yeb/runner'
require 'yeb/process'

module Yeb
  class RackApp < SocketProxy
    RACK_RUNNER_SCRIPT = File.expand_path('../../../scripts/rack-runner.sh', __FILE__)
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

      @runner = get_runner(RACK_RUNNER_SCRIPT, 'PORT' => port.to_s)
      @runner.run

      time_left = MAX_SPAWN_TIME
      while time_left > 0 && @runner.process_alive? && !socket_ready?
        Yeb.logger.debug "waiting for port #{port} to accept connections"
        sleep 1
        time_left -= 1
      end

      if time_left == 0
        Yeb.logger.error "app \"#{name}\" hasn't exposed working socket in " \
          "#{MAX_SPAWN_TIME} seconds, killing it"
        @runner.kill_process
      end

      if socket_ready?
        Yeb.logger.debug "app \"#{name}\" is ready"
      else
        raise RackAppStartFailedError.new(name, path, RACK_RUNNER_SCRIPT, @runner.stdout, @runner.stderr, env, ruby)
      end
    end

    def dispose
      Yeb.logger.info "killing app \"#{name}\""
      @runner.kill_process
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

    private

    def env
      runner = get_runner('/usr/bin/env | sort')
      runner.run
      runner.output
    end

    def ruby
      runner = get_runner('ruby -v')
      runner.run
      runner.output
    end

    def get_runner(command, env = {})
      env = { 'DIR' => path }.merge(env)
      Runner.new(command, :env => env)
    end
  end

  class RackAppStartFailedError < AppConnectError
    attr_reader :command, :stdout, :stderr, :env, :ruby

    def initialize(app_name, path, command, stdout, stderr, env, ruby)
      super(app_name, path)
      @command = command
      @stdout = stdout.strip
      @stderr = stderr.strip
      @env = env
      @ruby = ruby
    end
  end
end
