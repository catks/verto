module Verto
  module DSL
    module Syntax
      def config(&block)
        Verto.config.instance_eval(&block)
      end

      def current_branch
        git('rev-parse --abbrev-ref HEAD').output.chomp.strip
      end

      def branch(*branch_names)
        branch_names.map(&:to_s).include? current_branch
      end

      def context(condition, &block)
        block.call if condition
      end

      def git(subcommand)
        sh("git #{subcommand}")
      end

      def sh(command)
        command_executor.run command
      end

      def command_options
        Verto.config.command_options
      end

      def before(&block)
        Verto.config.hooks << Hook.new(moment: :before, &block)
      end

      def after(&block)
        Verto.config.hooks << Hook.new(moment: :after, &block)
      end

      def before_command(command_name, &block)
        Verto.config.hooks << Hook.new(moment: :before, on: Hook::Contexts::Command.new(command_name), &block)
      end

      def after_command(command_name, &block)
        Verto.config.hooks << Hook.new(moment: :after, on: Hook::Contexts::Command.new(command_name), &block)
      end

      def file(filepath)
        DSL::File.new(filepath)
      end

      def env(environment_name)
        ENV[environment_name]
      end

      private

      def command_executor
        @command_executor ||= SystemCommandExecutor.new
      end
    end
  end
end
