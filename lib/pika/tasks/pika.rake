require 'rake'
require 'pika/runner'

namespace :pika do
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
end

task pika: ['pika:runner']
