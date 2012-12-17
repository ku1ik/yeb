module Yeb
  class Command
    attr_reader :command, :cwd

    def initialize(command, cwd = nil)
      @command = command
      @cwd = cwd
    end

    def full_command
      parts = []

      global_rc = File.expand_path("~/.yebrc")
      if File.exist?(global_rc)
        parts << "source #{global_rc}"
      end

      if cwd
        local_rc = File.expand_path("#{cwd}/.yebrc")
        if File.exist?(local_rc)
          parts << "source #{local_rc}"
        end
      end

      if cwd
        parts << "cd #{cwd}"
      end

      parts << command

      combined = parts.join(" && ")

      "/bin/bash -c '#{combined}'"
    end
  end
end
