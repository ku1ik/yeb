module Yeb
  class App
    attr_reader :name, :dir, :socket_path

    def initialize(name, dir, socket_path)
      @name = name
      @dir = dir
      @socket_path = socket_path
    end

    def spawn
      raise AppNotRecognizedError.new(name) unless File.exist?("#{dir}/config.ru")
      puts "spawning app #{name} in #{dir}"

      @stdin, @stdout, @stderr, @wait_thr =
        Open3.popen3("sh -l -c 'exec thin start -S #{socket_path}'", :chdir => dir)

      @stdin.close

      while @wait_thr.alive? && !File.exist?(socket_path)
        puts "waiting for #{socket_path}"
        sleep 1
      end

      unless File.exist?(socket_path)
        stdout = @stdout.read + @stderr.read
        raise AppStartFailedError.new(name, stdout)
      end
    end

    def shutdown
    #   @stdout.close
    #   @stderr.close
    #   @wait_thr.kill
    end

    def socket
      UNIXSocket.new(socket_path)
    end
  end
end
