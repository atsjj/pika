require 'pika/runner'

module Pika
  class Railtie < ::Rails::Railtie
    config.eager_load_namespaces << ::Pika

    config.pika = Pika::Runner.config

    initializer "pika.initialize", after: "dry.env.initialize" do
      load_initializer

      Pika.instance = Pika::Runner.new
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
