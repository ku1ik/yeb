module Yeb
  class Runner
    RUNNER_SCRIPT = File.expand_path('../../../scripts/runner.sh', __FILE__)

    def initialize(command, opts = {})
      env = opts[:env] || {}
      @process = Process.new("#{RUNNER_SCRIPT} #{command}", env)
    end

    def run
      @process.start
    end

    def stdout
      @process.stdout
    end

    def stderr
      @process.stderr
    end

    def output
      (stdout + stderr).strip
    end

    def process_alive?
      @process.alive?
    end

    def kill_process
      @process.stop
    end
  end
end
