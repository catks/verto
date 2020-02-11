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

    def call_before_hooks(current_context)
      call_hooks(:before, current_context)
    end

    def call_after_hooks(current_context)
      call_hooks(:after, current_context)
    end

    def call_hooks(moment, current_context)
      Verto.config.hooks
        .select { |hook| hook.moment == moment }
        .each { |hook| hook.call(current_context) }
    end
  end
end
