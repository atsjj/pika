module Pika
  class Railtie < ::Rails::Railtie
    initializer 'pika.initialize', after: 'dry.env.initialize' do
      Pika.config.logger = Rails.logger
      Pika.config.tasks.root = Rails.root.join('app', 'tasks')
      Pika.config.instance = Runner.new
    end

    rake_tasks do
      Dir.glob("#{File.expand_path(__dir__)}/tasks/**/*.rake").each { |f| load f }
    end
  end
end
