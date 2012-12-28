module Yeb
  class Process
    attr_reader :command

    def initialize(command)
      @command = command
    end

    def start
      @stdin, @stdout, @stderr, @wait_thread =
        Open3.popen3(command.env, command.command)

      @stdin.close
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
