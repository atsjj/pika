require 'active_support/core_ext/digest/uuid'
require 'bunny'
require 'dry/core/constants'
require 'dry/initializer'
require 'oj'

module Pika
  class Message
    extend Dry::Initializer
    include Dry::Core::Constants

    attr_accessor :response

    param :url
    param :exchange_name
    param :routing_key

    def connection
      @connection ||= Bunny.new(url.to_s).yield_self do |bunny|
        bunny.start
        bunny
      end
    end

    def call(message, opts = EMPTY_HASH)
      options = if opts.is_a?(Bunny::MessageProperties)
        opts.to_hash
      elsif opts.nil?
        EMPTY_HASH
      else
        opts
      end

      options.fetch(:routing_key) { options[:routing_key] = routing_key }
      options.fetch(:correlation_id) { options[:correlation_id] = Digest::UUID.uuid_v4 }

      connection.with_channel do |channel|
        channel.topic(exchange_name)
          .publish(Oj.dump(message, mode: :strict), options)
      end
    ensure
      connection.close

      @connection = nil
    end
  end
end

