require 'yeb/command'
require 'yeb/process'
require 'yeb/error'

module Yeb
  class RackApp
    @@apps = {}

    attr_reader :name, :dir, :socket_path

    def initialize(name, dir, socket_path)
      @name = name
      @dir = dir
      @socket_path = socket_path
      @@apps[name] = self # need to prevent garbage collection and closing of @stdout and @stderr
    end

    def spawn
      puts "spawning app #{name} in #{dir}"

      @process = Process.new(command)
      @process.start

      while @process.alive? && !File.exist?(socket_path)
        puts "waiting for #{socket_path}"
        sleep 1
      end

      unless File.exist?(socket_path)
        raise AppStartFailedError.new(name, @process.stdout, @process.stderr, env)
      end
    end

    def command
      if File.exist?("#{dir}/config.ru")
        Command.new("#{thin} start -S #{socket_path}", dir)
      else
        raise AppNotRecognizedError.new(name)
      end
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

  class AppNotRecognizedError < Error; end
end
