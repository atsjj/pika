require 'active_support'

module Pika
  extend ActiveSupport::Autoload

  autoload :Callbacks
  autoload :Configuration
  autoload :Enum
  autoload :Graph
  autoload :Hash
  autoload :Initializer
  autoload :Logging
  autoload :LogSubscriber
  autoload :Message
  autoload :MessageProperties
  autoload :MessagePropertiesHeaders
  autoload :MessagePropertiesHeadersPika
  autoload :Mode
  autoload :Rfc
  autoload :Runner
  autoload :Struct
  autoload :Task
  autoload :Types
  autoload :VERSION

  class << self
    def config
      Configuration.config
    end

    def env
      instance.container
    end

    def instance
      config.instance
    end
  end
end

require 'pika/railtie' if defined?(Rails::Railtie)
