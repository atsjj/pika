require 'bunny'
require 'dry/core/class_attributes'
require 'dry/core/inflector'
require 'oj'
require 'pika/callbacks'
require 'pika/initializer'
require 'pika/log_subscriber'
require 'pika/logging'
require 'pika/mode'

module Pika
  class Task
    extend Initializer
    extend Dry::Core::ClassAttributes
    include Callbacks
    include Logging

    defines :channel_name, :logger, :max_retries, :modes, :prefetch,
            :queue_name, :requeue_on_rejection, :routing_key, :verbose_event_logs

    class << self
      def default_name
        Dry::Core::Inflector.underscore(name.to_s.gsub('Task', ''))
          .tr('/', '_').tr('_', '.')
      end
    end

    channel_name 'pika'

    logger Rails.logger

    max_retries 5

    modes Mode.rx | Mode.tx

    prefetch 1

    queue_name nil

    requeue_on_rejection false

    routing_key nil

    verbose_event_logs true

    option :connection, default: -> { nil }

    option :channel, default: -> { nil }

    option :channel_name, default: -> { self.class.channel_name }

    option :delivery_info, default: -> { nil }

    option :logger, default: -> { self.class.logger }

    option :max_retries, default: -> { self.class.max_retries }

    option :message, default: -> { {} }

    option :message_properties, default: -> {
      Bunny::MessageProperties.new({ correlation_id: Digest::UUID.uuid_v4 })
    }

    option :modes, default: -> { Mode.new(self.class.modes) }

    option :name, default: -> { self.class.default_name }

    option :prefetch, default: -> { self.class.prefetch }

    option :queue_name, default: -> { self.class.queue_name || self.class.default_name }

    option :routing_key, default: -> { self.class.routing_key || self.class.default_name }

    option :requeue_on_rejection, default: -> { self.class.requeue_on_rejection }

    option :exchange, default: -> {
      if channel.nil?
        nil
      else
        channel.topic(channel_name, auto_delete: false)
      end
    }

    option :queue, default: -> {
      if modes.rx?
        if channel.nil? || exchange.nil?
          nil
        else
          channel.queue(queue_name, auto_delete: false)
            .bind(exchange, routing_key: routing_key)
        end
      else
        nil
      end
    }

    def requeue_on_rejection?
      requeue_on_rejection
    end

    def bind
      (queue && self) || self
    end

    def acknowledge
      run_callbacks(:acknowledge) do
        channel.acknowledge(delivery_info.delivery_tag, false)
      end
    end

    def reject
      run_callbacks(:reject) do
        channel.reject(delivery_info.delivery_tag, requeue_on_rejection?)
      end
    end

    def perform
      # this should have before, around and after hooks
    end

    def call
      run_callbacks(:perform) do
        begin
          perform
          acknowledge
        rescue => exception
          reject

          logger.error({
            task: name,
            message: exception.message,
            backtrace: exception.backtrace,
            arguments: [{
              delivery_info: delivery_info,
              message_properties: message_properties
            }]
          })
        end
      end
    end

    def subscribe
      run_callbacks(:subscribe) do
        if modes.rx?
          queue.subscribe(manual_ack: true) do |delivery_info, message_properties, message|
            with(delivery_info: delivery_info, message_properties: message_properties,
              message: Oj.strict_load(message)).call
          end
        end
      end
    end

    def publish(message, opts = message_properties)
      run_callbacks(:publish) do
        options = if opts.is_a?(Bunny::MessageProperties)
          opts.to_hash
        elsif opts.nil?
          {}
        else
          opts
        end

        options.fetch(:routing_key) { options[:routing_key] = name }
        options.fetch(:correlation_id) { options[:correlation_id] = Digest::UUID.uuid_v4 }

        exchange.publish(Oj.dump(message, mode: :strict), options)
      end
    end
  end
end
