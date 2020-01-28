require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :console do
  `irb -r ./lib/verto -r ./spec/helpers/test_repo.rb`
end
