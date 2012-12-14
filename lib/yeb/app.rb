module Yeb
  class App
    def initialize(name)
      @name = name
    end

    def spawn(dir, socket_path)
      puts "spawning app #{@name} in #{dir}"

      @stdin, @stdout, @stderr, @wait_thr =
        Open3.popen3("sh -l -c 'exec thin start -S #{socket_path}'", :chdir => dir)

      @stdin.close

      while @wait_thr.alive? && !File.exist?(socket_path)
        puts "waiting for #{socket_path}"
        sleep 1
      end

      File.exist?(socket_path)
    rescue => e
      # puts e
      # puts e.message
      # puts e.backtrace
    end

    # def shutdown
    #   @stdout.close
    #   @stderr.close
    #   @wait_thr.kill
    # end
  end
end
