require 'socket'

require 'yeb/app'

module Yeb
  class UnixSocketProxy < App
    attr_reader :path

    def initialize(name, path)
      super(name)
      @path = path
    end

    def connect
      UNIXSocket.new(path)
    end

    def spawn
      # no op
    end
  end
end
