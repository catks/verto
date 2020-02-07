module Verto
  module DSL
    def self.load_file(filepath)
      vertofile_content = IO.read(filepath)

      parser.new.instance_eval(vertofile_content)
    end

    def self.parser
      @parser ||= Class.new { include Verto::DSL }
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

    private

    def command_executor
      @command_executor ||= SystemCommandExecutor.new
    end
  end
end
