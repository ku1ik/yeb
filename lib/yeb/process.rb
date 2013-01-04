module Yeb
  class Process
    attr_reader :command, :env

    def initialize(command, env)
      @command = command
      @env = env || {}
    end

    def start
      @stdin, @stdout, @stderr, @wait_thread =
        Open3.popen3(env, command)

      @stdin.close
    end

    def stop
      ::Process.kill("KILL", @wait_thread[:pid])
    end

    def alive?
      @wait_thread.alive?
    end

    def stdout
      @wait_thread.value # wait for process to finish
      out = @stdout.read
      @stdout.close
      out
    end

    def stderr
      @wait_thread.value # wait for process to finish
      err = @stderr.read
      @stderr.close
      err
    end
  end
end
