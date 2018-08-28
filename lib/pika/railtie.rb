module Pika
  class Railtie < ::Rails::Railtie
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
      load 'tasks/pika.rake'
    end
  end
end
