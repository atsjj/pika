module Pika
  module Dataset
    NULL = Object.new

    class RiakMapBackend
      def initialize(host: nil, namespace: nil)
        raise "host must be provided" if host.nil?
        raise "namespace must be provided" if namespace.nil?

        @client = Riak::Client.new(host: host)
        @backend = @client.bucket(namespace)
      end

      def [](key)
        @backend[key].data
      rescue
        nil
      end

      def []=(key, value)
        entry = @backend.get_or_new(key)
        entry.data = value
        entry.store

        raise KeyError, 'key not found' unless @backend.exists?(key)

        value
      end

      def key?(key)
        @backend.exists?(key)
      end

      def fetch(key, default_value = NULL)
        @backend.get(key).data
      rescue
        block_given? ? yield(key) : (NULL == default_value ? raise_fetch_no_key : default_value)
      end

      def delete(key)
        data = @backend[key].data

        @backend.delete(key)

        data
      end

      def clear
        # noop
      end

      def size
        # noop
      end

      private

      def raise_fetch_no_key
        raise KeyError, 'key not found'
      end
    end

    class RiakMap < Concurrent::Map
      def initialize(options = nil, &block)
        super(options, &block)

        @backend = RiakMapBackend.new(options)
      end
    end

    class CacheMapBackend
      def initialize
      end

      def [](key)
        # puts "[](#{key}): #{Rails.cache.read(key)}"
        Rails.cache.read(key)
      rescue
        nil
      end

      def []=(key, value)
        Rails.cache.write(key, value)

        # puts "[]=(#{key}, value): #{Rails.cache.read(key)}"

        value
      end

      def key?(key)
        # puts "key?(#{key}): #{Rails.cache.exist?(key)}"

        Rails.cache.exist?(key)
      end

      def fetch(key, default_value = NULL)
        if Rails.cache.exist?(key)
          # puts "fetch(#{key}, default_value): #{Rails.cache.read(key)}"

          Rails.cache.read(key)
        else
          block_given? ? yield(key) : (NULL == default_value ? raise_fetch_no_key : default_value)
        end
      end

      def fetch_multi(*keys)
        Hash[Rails.cache.read_multi(*keys)].tap { |h| keys.each { |k| h.fetch(k) { h[k] = nil } } }
      end

      def delete(key)
        data = Rails.cache.fetch(key, nil)

        Rails.cache.delete(key)

        # puts "delete(#{key}): #{Rails.cache.exist?(key)}"

        data
      end

      def clear
        # noop
      end

      def size
        # noop
      end

      private

      def raise_fetch_no_key
        raise KeyError, 'key not found'
      end
    end

    class CacheMap < Concurrent::Map
      def initialize(options = nil, &block)
        super(options, &block)

        @backend = CacheMapBackend.new
      end

      def fetch_multi(*keys)
        @backend.fetch_multi(*keys)
      end
    end
  end
end
