require 'active_support/core_ext/digest/uuid'
require 'bunny'
require 'dry/core/constants'
require 'dry/initializer'
require 'oj'

module Pika
  class Rfc
    extend Dry::Initializer
    include Dry::Core::Constants

    attr_accessor :response

    param :url
    param :queue

    def connection
      @connection ||= Bunny.new(url.to_s).yield_self do |bunny|
        bunny.start
        bunny
      end
    end

    def channel
      @channel ||= connection.create_channel
    end

    def response_queue
      @response_queue ||= channel.queue('', auto_delete: true, exclusive: true)
    end

    def exchange
      @exchange ||= channel.default_exchange
    end

    def ticket
      @ticket ||= Digest::UUID.uuid_v4
    end

    def lock
      @lock ||= Mutex.new
    end

    def condition
      @condition ||= ConditionVariable.new
    end

    def call(options = EMPTY_HASH)
      Oj.default_options = Hash({ mode: :strict })

      instance = self
      json = Oj.dump(options)

      response_queue.subscribe do |delivery_info, properties, payload|
        if properties[:correlation_id] == instance.ticket
          instance.response = payload
          instance.lock.synchronize { instance.condition.signal }
        end
      end

      exchange.publish(json, routing_key: queue, correlation_id: ticket,
        reply_to: response_queue.name)

      lock.synchronize { condition.wait(lock) }

      response
    end

    def execute(options = EMPTY_HASH)
      call(options) || Oj.dump(EMPTY_HASH)
    ensure
      channel.close
      connection.close

      @channel = nil
      @condition = nil
      @connection = nil
      @exchange = nil
      @lock = nil
      @response_queue = nil
      @ticket = nil
    end
  end
end

