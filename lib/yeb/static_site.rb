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

      if File.file?(filename)
        [200, File.read(filename)]
      elsif File.file?(filename + '.html')
        [200, File.read(filename + '.html')]
      elsif File.file?(filename + 'index.html')
        [200, File.read(filename + 'index.html')]
      else
        [404, "#{req.path} not found"]
      end
    end

    def alive?
      File.directory?(path)
    end

    def start
      # no op
    end

  end
end
