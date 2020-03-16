require "bundler/setup"
require "byebug"

require_relative "helpers/test_repo"
require_relative "helpers/test_command"
require_relative "helpers/file_helpers"

require 'simplecov'
SimpleCov.start

require "verto"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include FileHelpers
end
