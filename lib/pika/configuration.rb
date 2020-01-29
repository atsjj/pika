require 'dry/configurable'
require 'dry/core/constants'

module Pika
  class Configuration
    extend Dry::Configurable
    include Dry::Core::Constants

    setting(:amqp_url, EMPTY_STRING)
    setting(:instance)
    setting(:logger, ActiveSupport::Logger.new(STDOUT))
    setting(:tasks) do
      setting(:root)
    end
  end
end
