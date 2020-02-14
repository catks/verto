module Verto
  class BaseCommand < Thor
    def self.exit_on_failure?
      true
    end

    private

    def command_error!(message)
      raise Thor::Error, message
    end

    def options
      super.merge Verto.config.command_options
    end

    def call_hooks(moments = [], with_attributes: {})
      moments_to_call = ([] << moments).flatten

      moments_to_call.each do |moment|
        Verto.config.hooks
          .select { |hook| hook.moment == moment.to_sym }
          .each { |hook| hook.call(with_attributes: with_attributes) }
      end
    end
  end
end
