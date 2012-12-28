module Yeb
  class Command
    attr_reader :command, :env

    def initialize(command, opts = {})
      @command = command
      @env = opts[:env] || {}
    end
  end
end
