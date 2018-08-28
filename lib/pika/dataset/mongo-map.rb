require 'base64'

module Pika
  module Dataset
    NULLY = Object.new

    class MongoMapBackend
      def initialize(collection: :pika, uri: nil)
        Mongo::Logger.logger.level = Logger::INFO

        @client = Mongo::Client.new(uri)
        @backend = @client[collection]
      end

      def [](key)
        @backend.find({ _id: key }).first.fetch('value')
      rescue
        nil
      end

      def []=(key, value)
        @backend.find({ _id: key })
          .update_one({ 'value' => value }, { upsert: true }) && value
      end

      def key?(key)
        @backend.find({ _id: key }).count > 0
      end

      def fetch(key, default_value = NULLY)
        @backend.find({ _id: key }).first.fetch('value')
      rescue
        block_given? ? yield(key) : (NULLY == default_value ? raise_fetch_no_key : default_value)
      end

      def fetch_multi(*keys)
        @backend.find({ _id: { '$in' => keys } })
          .map { |h| Hash[{ h.fetch('_id', nil) => h.fetch('value') }] }
          .reduce(&:merge)
          .tap { |h| keys.each { |k| h.fetch(k) { h[k] = nil } } }
      end

      def delete(key)
        @backend.find_one_and_delete({ _id: key }).fetch('value')
      rescue
        nil
      end

      def delete_multi(*keys)
        @backend.delete_many({ _id: { '$in' => keys } })
      end

      def keys
        @backend.distinct('_id')
      end

      def clear
        @backend.drop
        self
      end

      def size
        @backend.count
      end

      private

      def raise_fetch_no_key
        raise KeyError, 'key not found'
      end
    end

    class MongoMap < Concurrent::Map
      def initialize(options = nil, &block)
        super(options, &block)

        @backend = MongoMapBackend.new(options)
      end

      def fetch_multi(*keys)
        @backend.fetch_multi(*keys)
      end

      def delete_multi(*keys)
        @backend.delete_multi(*keys)
      end

      def keys
        @backend.keys
      end
    end
  end
end
