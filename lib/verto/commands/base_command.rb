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

    def call_before_hooks(current_context, with_attributes: {})
      call_hooks(:before, current_context, with_attributes)
    end

    def call_after_hooks(current_context, with_attributes: {})
      call_hooks(:after, current_context, with_attributes)
    end

    def call_hooks(moment, current_context, with_attributes = {})
      Verto.config.hooks
        .select { |hook| hook.moment == moment }
        .each { |hook| hook.call(current_context, with_attributes: with_attributes) }
    end
  end
end
