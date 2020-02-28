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
        branch_names.any? do |branch|
          return branch.match?(current_branch) if branch.is_a?(Regexp)

          branch.to_s.include? current_branch
        end
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

      def sh!(command)
        raise Verto::ExitError unless sh(command).success?
      end

      def command_options
        Verto.config.command_options
      end

      def on(moment, &block)
        Verto.config.hooks << Hook.new(moment: moment, &block)
      end

      def before(&block)
        Verto.config.hooks << Hook.new(moment: :before, &block)
      end

      def after(&block)
        Verto.config.hooks << Hook.new(moment: :after, &block)
      end

      def before_command(command_name, &block)
        Verto.config.hooks << Hook.new(moment: "before_#{command_name}", &block)
      end

      def after_command(command_name, &block)
        Verto.config.hooks << Hook.new(moment: "after_#{command_name}", &block)
      end

      def file(filepath)
        DSL::File.new(filepath)
      end

      def env(environment_name)
        ENV[environment_name]
      end

      def confirm(text)
        shell_basic.yes?("#{text} (y/n)")
      end

      def error(text)
        stderr << text
      end

      def error!(text)
        error(text)

        raise Verto::ExitError
      end

      private

      def command_executor
        @command_executor ||= SystemCommandExecutor.new
      end

      def shell_basic
        @shell_basic ||= Thor::Shell::Basic.new
      end

      def stderr
        Verto.stderr
      end
    end
  end
end
