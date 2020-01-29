require 'active_support/core_ext/digest/uuid'
require 'dry/core/constants'

module Pika
  class Struct < Dry::Struct
    class << self
      def with(*args)
        new(*args)
      end
    end

    alias_method :with, :new

    transform_keys(&:to_sym)

    transform_types do |type|
      if type.default?
        type.constructor do |value|
          value.nil? ? Types::Undefined : value
        end
      else
        type
      end
    end
  end
end
