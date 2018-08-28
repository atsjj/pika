require 'bunny'
require 'dry/container'
require 'pathname'

module Pika
  class Runner
    extend Initializer
    extend Dry::Core::ClassAttributes

    param :amqp_url

    def connection
      @connection ||= -> {
        c = Bunny.new(amqp_url)
        c.start
        c
      }.call
    end

    def directory
      Rails.root.join('app', 'tasks')
    end

    def tasks
      Dir[directory.join('**/*.rb')].map do |file|
        require file

        file_name = file.sub(/^#{directory}\//, '').sub(/\.rb\z/, '')
        klass_name = ActiveSupport::Inflector.camelize(file_name)

        ActiveSupport::Inflector.constantize(klass_name)
      end
    end

    def load_tasks
      Dir[directory.join('**/*.rb')].map do |file|
        require file

        Pathname.new(file).relative_path_from(directory)
      end
    end

    def tasks
      load_tasks.map do |task|
        name = task.dirname.join(task.basename('.rb')).to_s

        key = name.gsub(/\//,'.').sub(/_task\z/,'')
        value = ActiveSupport::Inflector
          .constantize(ActiveSupport::Inflector
            .camelize(name))

        [key, value]
      end
    end

    def load_channels(into = Dry::Container.new)
      tasks.reduce(into) do |container, (k, v)|
        channel = connection.create_channel
        channel.prefetch(v.prefetch)

        container.register(k, channel)
        container
      end
    end

    def load_container(into = Dry::Container.new)
      tasks.reduce(into) do |container, (k, v)|
        container.register(k) do
          v.new(connection: connection, channel: channels.resolve(k))
        end

        container
      end
    end

    def channels
      @channels ||= load_channels
    end

    def container
      @container ||= load_container
    end

    def call(only: nil, except: nil)
      condition = ConditionVariable.new
      condition_received = nil
      lock = Mutex.new
      keys = container.keys & (only || container.keys) - (except || [])

      instances = keys.map { |k| puts k; container.resolve(k).bind }
      instances.each(&:subscribe)

      %w[INT QUIT TERM USR1].each do |signal|
        Signal.trap(signal) do |number|
          condition_received = number
          condition.signal
        end
      end

      Thread.new do
        lock.synchronize do
          condition.wait(lock) until condition_received

          instances.each { |task| task.channel.close }
          instances.each { |task| task.connection.close }

          puts "#{Signal.signame(condition_received)}: Exiting..."
        end
      end.join
    end
  end
end
