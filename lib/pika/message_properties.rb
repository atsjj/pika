require 'active_support/core_ext/digest/uuid'
require 'dry/core/constants'

module Pika
  class MessageProperties < Struct
    include Dry::Core::Constants

    class << self
      def new(attributes = EMPTY_HASH)
        instance = attributes.equal?(EMPTY_HASH) ? super() : super(attributes)
        options = attributes.to_h.deep_merge(instance.to_h)

        if options.key?(:from)
          options[:headers][:pika][:from] = options.delete(:from)
        end

        if options.key?(:as)
          options[:headers][:pika][:as] = options.delete(:as)
        end

        if options.key?(:cc)
          options[:headers][:pika][:cc] = options.delete(:cc)
        end

        if options.key?(:record_id)
          options[:headers][:pika][:record_id] = options.delete(:record_id)
        end

        super(options)
      end
    end

    attribute :app_id, Types::Coercible::String.meta(omittable: true)
    attribute :cluster_id, Types::Coercible::String.meta(omittable: true)
    attribute :content_encoding, Types::Coercible::String.meta(omittable: true)
    attribute :content_type, Types::Coercible::String.meta(omittable: true)
    attribute :correlation_id, Types::Coercible::String.default(Digest::UUID.uuid_v4)
    attribute :delivery_mode, Types::Coercible::Integer.meta(omittable: true)
    attribute :expiration, Types::Coercible::String.meta(omittable: true)
    attribute :headers, MessagePropertiesHeaders.default(MessagePropertiesHeaders.new)
    attribute :message_id, Types::Coercible::String.meta(omittable: true)
    attribute :priority, Types::Coercible::Integer.meta(omittable: true)
    attribute :reply_to, Types::Coercible::String.default('')
    attribute :routing_key, Types::Coercible::String.default(EMPTY_STRING)
    attribute :timestamp, Types::Coercible::Integer.meta(omittable: true)
    attribute :type, Types::Coercible::String.meta(omittable: true)
    attribute :user_id, Types::Coercible::String.meta(omittable: true)

    def from
      headers.pika.from
    end

    def as
      headers.pika.as
    end

    def cc
      headers.pika.cc
    end

    def record_id
      headers.pika.record_id
    end
  end
end
