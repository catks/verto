module Verto
  module DSL
    def self.load_file(filepath)
      vertofile_content = IO.read(filepath)

      parser.instance_eval(vertofile_content)
    end

    def self.parser
      @parser ||= Class.new { include Verto::DSL }.new
    end

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

    def before_command(command_name, &block)
      Verto.config.hooks << Hook.new(moment: :before, on: Hook::Contexts::Command.new(command_name), &block)
    end

    def after_command(command_name, &block)
      Verto.config.hooks << Hook.new(moment: :after, on: Hook::Contexts::Command.new(command_name), &block)
    end

    private

    def command_executor
      @command_executor ||= SystemCommandExecutor.new
    end

    def current_moment
      @current_moment || :before
    end
  end
end
