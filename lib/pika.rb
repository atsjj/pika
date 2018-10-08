require 'dry/struct'
require 'pika/graph'
require 'pika/hash'
require 'pika/message'
require 'pika/rfc'
require 'pika/runner'
require 'pika/task'

module Pika
  class << self
    attr_accessor :instance

    def env
      instance.container
    end
  end
end

require 'pika/railtie' if defined?(Rails)
