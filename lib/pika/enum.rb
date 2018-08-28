module Pika
  class Enum
    class << self
      private

      def attr_enum(key, value)
        define_singleton_method("#{key}") { value }

        define_method("#{key}?") { @attrs & value != 0 }
        define_method("#{key}=") { |v| v ? @attrs |= value : @attrs &= ~value }
      end
    end

    def initialize(attrs = 0)
      @attrs = attrs
    end

    def to_i
      @attrs
    end
  end
end
