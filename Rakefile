require "bundler/gem_tasks"
require "rspec/core/rake_task"
require_relative "lib/verto"
require_relative "spec/helpers/test_repo.rb"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc 'Verto REPL'
task :console do
  require 'irb'
  ARGV.clear
  IRB.start
end

namespace :temp_repo do
  desc 'Initialize a temp git repo'
  task :init do
    TestRepo.new.init!
  end

  desc 'clear the temp git repo'
  task :clear do
    TestRepo.new.clear!
  end
end
