require 'stringio'
require 'webrick/httpresponse'

module Yeb
  class Response < WEBrick::HTTPResponse
    def initialize
      super({
        :HTTPVersion => '1.0',
        :ServerSoftware => 'yeb'
      })

      self.keep_alive = false

      if block_given?
        yield self
      end
    end
  end
end
