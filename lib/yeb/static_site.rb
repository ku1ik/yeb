# these 2 should be really required by webrick/httprequest
require 'timeout'
require 'webrick/utils'

require 'webrick/httprequest'

require 'yeb/app'
require 'yeb/response'

module Yeb
  class StaticSite < App

    def call(request)
      req = WEBrick::HTTPRequest.new({})
      req.parse(request)

      if req.path == '/'
        filename = "#{path}/index.html"
      else
        filename = "#{path}/#{req.path}"
      end

      if File.exist?(filename)
        response = Response.new do |r|
          r.status = 200
          r.body = File.read(filename)
        end
      else
        response = Response.new do |r|
          r.status = 404
          r.body = "#{req.path} not found"
        end
      end

      response.to_s
    end

    def alive?
      true
    end

    def spawn
      # no op
    end

  end
end
