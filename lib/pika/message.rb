require 'active_support/core_ext/digest/uuid'
require 'bunny'
require 'dry-initializer'
require 'oj'

module Pika
  class Message
    extend Dry::Initializer

    attr_accessor :response

    param :url
    param :exchange_name
    param :routing_key

    def connection
      @connection ||= -> {
        c = Bunny.new(url.to_s)
        c.start
        c
      }.call
    end

    def channel
      @channel ||= connection.create_channel
    end

    def exchange
      @exchange ||= channel.topic(exchange_name, auto_delete: false)
    end

    def call(message, opts = {})
      options = if opts.is_a?(Bunny::MessageProperties)
        opts.to_hash
      elsif opts.nil?
        {}
      else
        opts
      end

      options.fetch(:routing_key) { options[:routing_key] = routing_key }
      options.fetch(:correlation_id) { options[:correlation_id] = Digest::UUID.uuid_v4 }

      exchange.publish(Oj.dump(message, mode: :strict), options)
    ensure
      channel.close
      connection.close

      @channel = nil
      @connection = nil
      @exchange = nil
    end
  end
end

