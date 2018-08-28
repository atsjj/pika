require 'pika/graph'
require 'pika/hash'
require 'pika/task'
require 'pika/runner'

module Pika
  class << self
    attr_accessor :env
  end
end
