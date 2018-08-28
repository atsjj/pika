require 'pika/graph'
require 'pika/hash'
require 'pika/task'
require 'pika/runner'

module Pika
  class << self
    attr_accessor :instance

    def env
      instance.container
    end
  end
end

require 'pika/railtie' if defined?(Rails)
