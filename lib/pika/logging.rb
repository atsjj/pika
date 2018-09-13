require 'active_support/concern'
require 'active_support/core_ext/string/filters'
require 'active_support/logger'
require 'active_support/tagged_logging'

module Pika
  module Logging
    extend ActiveSupport::Concern

    included do
      around_acknowledge do |task, block|
        ActiveSupport::Notifications.instrument('acknowledge.pika_task', task: task, &block)
      end

      around_perform do |task, block|
        ActiveSupport::Notifications.instrument('perform.pika_task', task: task, &block)
      end

      around_publish do |task, block|
        ActiveSupport::Notifications.instrument('publish.pika_task', task: task, &block)
      end

      around_reject do |task, block|
        ActiveSupport::Notifications.instrument('reject.pika_task', task: task, &block)
      end

      around_subscribe do |task, block|
        ActiveSupport::Notifications.instrument('subscribe.pika_task', task: task, &block)
      end
    end
  end
end
