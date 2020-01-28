module Verto
  class BaseCommand < Thor
    def self.exit_on_failure?
      true
    end

    private

    def command_error!(message)
      raise Thor::Error, message
    end
  end
end
