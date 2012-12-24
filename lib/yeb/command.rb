module Yeb
  class Command
    attr_reader :command, :opts

    def initialize(command, opts = {})
      @command = command
      @opts = opts
    end

    def full_command
      parts = []

      if env = opts[:env]
        parts << env.inject('') do |acc, kv|
          acc << "#{kv[0]}=#{kv[1]} "
          acc
        end
      end

      global_rc = File.expand_path("~/.yebrc")
      if File.exist?(global_rc)
        parts << "source #{global_rc}"
      end

      if cwd = opts[:cwd]
        local_rc = File.expand_path("#{cwd}/.yebrc")
        if File.exist?(local_rc)
          parts << "source #{local_rc}"
        end

        parts << "cd #{cwd}"
      end

      parts << command

      combined = parts.join(" && ").gsub("'", %('"'"'))
      puts combined

      "/bin/bash -c '#{combined}'"
    end

    alias to_s full_command
  end
end
