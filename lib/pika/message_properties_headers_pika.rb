require 'active_support/core_ext/digest/uuid'
require 'dry/core/constants'

module Pika
  class MessagePropertiesHeadersPika < Struct
    include Dry::Core::Constants

    attribute :from, Types::Coercible::String.default(EMPTY_STRING)
    attribute :as, Types::Coercible::String.default(EMPTY_STRING)
    attribute :cc, Types::Coercible::String.default(EMPTY_STRING)
    attribute :record_id, Types::Coercible::String.default(EMPTY_STRING)
  end
end
