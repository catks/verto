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

    def stderr
      Verto.stderr
    end

    def call_hooks(moments = [], with_attributes: {})
      moments_to_call = ([] << moments).flatten

      moments_to_call.each do |moment|
        Verto.config.hooks
          .select { |hook| hook.moment == moment.to_sym }
          .each do |hook|
            Verto.current_moment = hook.moment
            hook.call(with_attributes: with_attributes)
          end
      end
    end
  end
end
