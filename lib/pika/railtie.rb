require 'pika/runner'

module Pika
  class Railtie < ::Rails::Railtie
    railtie_name :pika

    config.eager_load_namespaces << ::Pika

    initializer "pika.initialize" do
      load_initializer
    end

    def load_initializer
      load "#{root}/config/initializers/pika.rb"
    rescue LoadError
      # do nothing
    end

    def root
      ::Rails.root
    end

    rake_tasks do
      path = File.expand_path(__dir__)
      Dir.glob("#{path}/tasks/**/*.rake").each { |f| load f }
    end
  end
end
