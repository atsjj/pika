require 'pika/runner'

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
      puts "Running rake task stuff"

      namespace :pika do
        desc "Runner"
        task :runner => :environment do
          runner = Pika::Runner.new
          runner.call(except: ['application'])
        end

        desc "Run only tasks"
        task :tasks => :environment do
          runner = Pika::Runner.new
          runner.call(except: ['application'])
        end

        desc "Run only log"
        task :log => :environment do
          runner = Pika::Runner.new
          runner.call(except: ['application'])
        end
      end

      task pika: ['pika:runner']
    end
  end
end
