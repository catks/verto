require "thor"
require "dry-container"
require "dry-configurable"
require "dry-auto_inject"
require "vseries"
require "pathname"

require "verto/version"
require "verto/utils/command_options"

module Verto
  extend Dry::Configurable

  setting :pre_release do
    setting :initial_number, 1
  end

  setting :project do
    setting :path, './'
  end

  setting :output do
    setting :stdout_to, nil
    setting :stderr_to, nil
  end

  setting :hooks, []
  setting :command_options, CommandOptions.new

  ExitError = Class.new(Thor::Error)
  CommandError = Class.new(ExitError)

  def self.root_path
    Pathname.new File.expand_path(File.dirname(__FILE__) + '/..')
  end

  def self.project_path
    Pathname.new Verto.config.project.path
  end

  def self.container
    @container ||= Dry::Container.new.tap do |container|
      container.register('system_command_executor') { SystemCommandExecutor.new }
      container.register('system_command_executor_without_output') { SystemCommandExecutor.new(stdout: nil, stderr: nil) }

      container.register('tag_repository') { TagRepository.new }

      container.register('stdout', memoize: true) do
        stdout = Verto.config.output.stdout_to
        stdout && Verto.project_path.join(stdout).open('a+') || $stdout
      end

      container.register('stderr', memoize: true) do
        stderr = Verto.config.output.stderr_to
        stderr && Verto.project_path.join(stderr).open('a+') || $stderr
      end

      # TODO: Remove project.path from container
      container.namespace('project') do
        register('path') { Verto.config.project.path }
      end
    end
  end

  def self.import
    @import ||= Dry::AutoInject(container)
  end

  def self.stderr
    Verto.container.resolve('stderr')
  end
end

require "verto/utils/semantic_version.rb"
require "verto/utils/system_command_executor"
require "verto/utils/tag_filter"
require "verto/utils/template"
require "verto/dsl"
require "verto/dsl/syntax"
require "verto/dsl/interpreter"
require "verto/dsl/hook"
require "verto/dsl/file"
require "verto/commands/base_command"
require "verto/commands/tag_command"
require "verto/commands/main_command"
require "verto/repositories/tag_repository"
