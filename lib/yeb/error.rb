module Yeb
  class Error < StandardError
    attr_reader :app_name

    def initialize(app_name)
      @app_name = app_name
    end
  end
end
