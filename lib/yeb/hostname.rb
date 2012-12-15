module Yeb
  class Hostname
    attr_reader :name

    def self.from_http_request(request)
      new(request[/Host: ([^\n\r]+)/, 1])
    end

    def initialize(name)
      @name = name
    end

    def root
      name[/(.+\.)?([^\.]+\.dev)$/, 2]
    end
  end
end
