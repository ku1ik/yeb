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
      root_name = name[/(.+\.)?([^\.]+\.[a-z]+)$/, 2]

      if root_name == name
        self
      else
        Hostname.new(root_name)
      end
    end

    def app_name
      name[/^(.+)\.[a-z]+$/, 1]
    end

    def to_s
      name
    end
  end
end
