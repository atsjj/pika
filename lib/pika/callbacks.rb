require 'active_support/callbacks'
require 'active_support/concern'

module Pika
  module Callbacks
    extend ActiveSupport::Concern
    include ActiveSupport::Callbacks

    included do
      define_callbacks :acknowledge
      define_callbacks :perform
      define_callbacks :publish
      define_callbacks :reject
      define_callbacks :subscribe
    end

    module ClassMethods
      def before_acknowledge(*filters, &blk)
        set_callback(:acknowledge, :before, *filters, &blk)
      end

      def after_acknowledge(*filters, &blk)
        set_callback(:acknowledge, :after, *filters, &blk)
      end

      def around_acknowledge(*filters, &blk)
        set_callback(:acknowledge, :around, *filters, &blk)
      end

      def before_perform(*filters, &blk)
        set_callback(:perform, :before, *filters, &blk)
      end

      def after_perform(*filters, &blk)
        set_callback(:perform, :after, *filters, &blk)
      end

      def around_perform(*filters, &blk)
        set_callback(:perform, :around, *filters, &blk)
      end

      def before_publish(*filters, &blk)
        set_callback(:publish, :before, *filters, &blk)
      end

      def after_publish(*filters, &blk)
        set_callback(:publish, :after, *filters, &blk)
      end

      def around_publish(*filters, &blk)
        set_callback(:publish, :around, *filters, &blk)
      end

      def before_reject(*filters, &blk)
        set_callback(:reject, :before, *filters, &blk)
      end

      def after_reject(*filters, &blk)
        set_callback(:reject, :after, *filters, &blk)
      end

      def around_reject(*filters, &blk)
        set_callback(:reject, :around, *filters, &blk)
      end

      def before_subscribe(*filters, &blk)
        set_callback(:subscribe, :before, *filters, &blk)
      end

      def after_subscribe(*filters, &blk)
        set_callback(:subscribe, :after, *filters, &blk)
      end

      def around_subscribe(*filters, &blk)
        set_callback(:subscribe, :around, *filters, &blk)
      end
    end
  end
end
