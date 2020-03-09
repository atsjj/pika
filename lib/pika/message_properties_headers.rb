require 'active_support/core_ext/digest/uuid'

module Pika
  class MessagePropertiesHeaders < Struct
    attribute :pika, MessagePropertiesHeadersPika.default(MessagePropertiesHeadersPika.new.freeze)
  end
end
