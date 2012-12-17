module Yeb
  class Error < StandardError
    attr_reader :app_name

    def initialize(app_name)
      @app_name = app_name
    end
  end

  class AppNotFoundError < Error; end

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
