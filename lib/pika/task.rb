require 'bunny'
require 'dry/core/class_attributes'
require 'dry/core/constants'
require 'dry/core/inflector'
require 'oj'
require 'pika/callbacks'
require 'pika/initializer'
require 'pika/log_subscriber'
require 'pika/logging'
require 'pika/message_properties'
require 'pika/mode'

module Pika
  class Task
    extend Initializer
    extend Dry::Core::ClassAttributes
    include Dry::Core::Constants
    include Callbacks
    include Logging

    defines :channel_name, :logger, :max_retries, :modes, :prefetch,
            :queue_name, :requeue_on_rejection, :routing_key,
            :verbose_event_logs

    class << self
      def default_name
        Dry::Core::Inflector.underscore(name.to_s.gsub('Task', ''))
          .tr('/', '.')
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

    option :message_properties, default: -> { Pika::MessageProperties.new }

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
        channel.topic(channel_name)
      end
    }

    option :queue, default: -> {
      if modes.rx?
        if channel.nil? || exchange.nil?
          nil
        else
          channel.queue(queue_name).bind(exchange, routing_key: routing_key)
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

          logger.error("task #{name}, #{exception.inspect}")
          logger.error(exception.backtrace.join("\n"))
          logger.error("message #{message}")
          logger.error("arguments(delivery_info) #{delivery_info}")
          logger.error("arguments(message_properties) #{message_properties}")
        end
      end
    end

    def sync(*args)
      raise "a block must be given" unless block_given?

      value = nil

      connection.with_channel do |tmp_channel|
        _correlation_id = Digest::UUID.uuid_v4
        tmp_queue = tmp_channel.temporary_queue
        options = publish_options(cc: tmp_queue.name, correlation_id: _correlation_id)
        instance = with(connection: connection, channel: tmp_channel, message_properties: options)
        condition = ConditionVariable.new
        lock = Mutex.new

        tmp_queue.subscribe do |tmp_delivery_info, tmp_message_properties, tmp_message|
          _message_properties = Pika::MessageProperties.new(tmp_message_properties)

          _task = if Pika.env.key?(_message_properties.from)
            Pika.env.resolve(_message_properties.from)
          else
            Pika::Task.new(name: _message_properties.from)
          end

          _task_instance = _task.with(delivery_info: tmp_delivery_info,
            message_properties: _message_properties,
            message: Oj.strict_load(tmp_message))

          value = yield(condition, _task_instance)
        end

        instance.call(*args)

        lock.synchronize do
          condition.wait(lock)
        end
      end

      value
    end

    def subscribe
      run_callbacks(:subscribe) do
        if modes.rx?
          queue.subscribe(manual_ack: true) do |delivery_info, message_properties, message|
            with(delivery_info: delivery_info,
              message_properties: Pika::MessageProperties.new(message_properties),
              message: Oj.strict_load(message)).call
          end
        end
      end
    end

    def publish_options(opts = EMPTY_HASH)
      options = message_properties.with(opts)

      if !opts.key?(:routing_key) || options.routing_key.equal?(EMPTY_STRING)
        options = options.with(routing_key: name)
      end

      if !opts.key?(:from) || options.headers.pika.from.equal?(EMPTY_STRING)
        options = options.with(from: name)
      end

      if !opts.key?(:as) || options.headers.pika.as.equal?(EMPTY_STRING)
        options = options.with(as: name)
      end

      options
    end

    def publish(message, opts = EMPTY_HASH)
      run_callbacks(:publish) do
        exchange.publish(Oj.dump(message, mode: :strict), publish_options(opts).to_h)
      end
    end
  end
end
