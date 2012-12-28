require 'logger'

module Yeb
  class Logger < ::Logger
    def initialize(*args)
      super
      self.level = DEBUG
    end
  end

  def self.logger
    @logger ||= Yeb::Logger.new(STDOUT)
  end

  def self.logger=(logger)
    @logger = logger
  end
end
