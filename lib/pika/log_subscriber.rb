require 'active_support/log_subscriber'

module Pika
  class LogSubscriber < ActiveSupport::LogSubscriber
    def acknowledge(event)
      debug do
        task = event.payload[:task]
        message(event, :acknowledge, "#{task.queue_name}@#{task.routing_key} (Correlation ID: #{task.message_properties.correlation_id})")
      end
    end

    def perform(event)
      debug do
        task = event.payload[:task]
        message(event, :perform, "#{task.queue_name}@#{task.routing_key} (Correlation ID: #{task.message_properties.correlation_id})")
      end
    end

    def publish(event)
      debug do
        task = event.payload[:task]
        message(event, :publish, "#{task.queue_name}@#{task.routing_key} (Correlation ID: #{task.message_properties.correlation_id})")
      end
    end

    def reject(event)
      debug do
        task = event.payload[:task]
        message(event, :reject, "#{task.queue_name}@#{task.routing_key} (Correlation ID: #{task.message_properties.correlation_id})")
      end
    end

    def subscribe(event)
      debug do
        task = event.payload[:task]
        message(event, :subscribe, "#{task.queue_name}@#{task.routing_key}")
      end
    end

    private

    def message(event, name, *strings)
      [
        [
          " ",
          event.payload[:task].class.name,
          name.to_s.capitalize,
          "(#{event.duration.round(1)}ms)"
        ].map { |s| color(s, CYAN, true) }.join(' '),
        *strings.map { |s| color(s, BLUE, true) }
      ].join(' ')
    end

    def cyan(string)
      color(string, CYAN, true)
    end
  end
end

Pika::LogSubscriber.attach_to :pika_task
