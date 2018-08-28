require 'rake'
require 'pika/runner'

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
