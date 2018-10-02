require 'rake'
require 'pika/runner'

namespace :pika do
  desc 'Runs before pika:runner'
  task before_runner: :environment do
  end

  desc 'Runs all tasks within the app/tasks folder'
  task runner: :environment do
    console = ActiveSupport::Logger.new(STDOUT)
    console.formatter = Rails.logger.formatter
    console.level = Rails.logger.level

    unless ActiveSupport::Logger.logger_outputs_to?(Rails.logger, STDOUT)
      Rails.logger.extend(ActiveSupport::Logger.broadcast(console))
    end

    Pika.instance.call(except: ['application'])
  end

  desc 'Runs after pika:runner'
  task after_runner: :environment do
  end
end

task pika: ['pika:before_runner', 'pika:runner', 'pika:after_runner']
