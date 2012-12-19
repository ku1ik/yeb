module Yeb
  class Hostname
    TLD_REGEXP = /dev|lvh\.me|(\d{1,3}\.){4}xip\.io/

    attr_reader :name

    def self.from_http_request(request)
      new(request[/Host: ([^\n\r]+)/, 1])
    end

    def initialize(name)
      @name = name
    end

    def root
      root_name = name[/(.+\.)?([^\.]+\.(#{TLD_REGEXP}))$/, 2]

      if root_name == name
        self
      else
        Hostname.new(root_name)
      end
    end

    def app_name
      name[/^(.+)\.(#{TLD_REGEXP})$/, 1]
    end

    def to_s
      name
    end
  end
end
