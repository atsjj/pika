require 'rake'
require 'pika/runner'

namespace :pika do
  desc 'Runs all tasks within the app/tasks folder'
  task runner: :environment do
    runner = Pika::Runner.new
    runner.call(except: ['application'])
  end
end

task pika: ['pika:runner']
