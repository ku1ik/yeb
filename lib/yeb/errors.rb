module Yeb
  class Error < StandardError
    attr_reader :app_name

    def initialize(app_name)
      @app_name = app_name
    end
  end

  class AppNotFoundError < Error; end

  class AppStartFailedError < Error
    attr_reader :stdout

    def initialize(app_name, stdout)
      super(app_name)
      @stdout = stdout
    end
  end

  class AppNotRecognizedError < Error; end
end
