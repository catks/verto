module Verto
  class BaseCommand < Thor
    def self.exit_on_failure?
      true
    end

    private

    def command_error!(message)
      raise Verto::CommandError, message
    end

    def options
      Verto.config.command_options.merge!(super)
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
