require 'bunny'
require 'concurrent-ruby'
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
require 'stud/trap'

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
      def inherited(subclass)
        super(subclass)

        subclass.abstract(false)
      end

      def abstract(value = true)
        @abstract = value
      end

      def abstract?
        @abstract
      end

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
          channel
            .queue(queue_name, auto_delete: true)
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

          logger.error("task #{name}, #{exception.inspect}")
          logger.error(exception.backtrace.join("\n"))
          logger.error("message #{message}")
          logger.error("arguments(delivery_info) #{delivery_info}")
          logger.error("arguments(message_properties) #{message_properties}")
        end
      end
    end

    def sync(*args, &block)
      raise "a block must be given" unless block_given?

      Concurrent::Promises.future(args, self, connection, block) do |t_args, b_task, t_connection, t_block|
        f_value = nil

        t_connection.with_channel do |t_channel|
          ['INT', 'QUIT', 'TERM', 'USR1'].each do |signal|
            Signal.trap(signal) do |code|
              t_channel.try(:close)

              raise "Exiting #{signal} #{code}"
            end
          end

          t_correlation_id = Digest::UUID.uuid_v4
          t_queue = t_channel.temporary_queue(auto_delete: true, exclusive: true)
          t_options = b_task.publish_options(cc: t_queue.name, correlation_id: t_correlation_id)
          t_instance = b_task.with(connection: t_connection, channel: t_channel, message_properties: t_options)
          t_instance.call(*t_args)
          t_consumer = t_queue.subscribe(block: true) do |b_delivery_info, b_message_properties, b_message|
            t_message_properties = Pika::MessageProperties.new(b_message_properties)

            if t_message_properties == 'error'
              t_error = Oj.strict_load(tmp_message)
                .fetch(_message_properties.from) {
                  Hash['message', '', 'backtrace', []]
                }

              t_exception = RuntimeError.new(t_error.fetch('message'))
              t_exception.set_backtrace(t_error.fetch('backtrace'))

              raise t_exception
            else
              t_task = if Pika.env.key?(t_message_properties.from)
                Pika.env.resolve(t_message_properties.from)
              else
                Pika::Task.new(name: t_message_properties.from)
              end

              t_task_instance = t_task.with(delivery_info: b_delivery_info,
                message_properties: t_message_properties,
                message: Oj.strict_load(b_message))

              t_value = t_block.call(t_task_instance)

              unless t_value.nil?
                f_value = t_value

                t_channel.close
              end
            end
          end
        end

        f_value
      end.value!
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
