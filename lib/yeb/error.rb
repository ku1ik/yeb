module Yeb
  class Error < StandardError
    attr_reader :app_name

    def initialize(app_name)
      @app_name = app_name
    end
  end

  class AppError < Error
    attr_reader :path

    def initialize(app_name, path)
      super(app_name)
      @path = path
    end
  end
end
