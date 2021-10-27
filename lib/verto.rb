# frozen_string_literal: true

require 'thor'
require 'dry-container'
require 'dry-configurable'
require 'dry-auto_inject'
require 'vseries'
require 'mustache'
require 'tty-prompt'
require 'tty-editor'
require 'pathname'
require 'securerandom'

require 'verto/version'
require 'verto/utils/command_options'

module Verto
  extend Dry::Configurable

  setting :pre_release do
    setting :initial_number, 1
    setting :default_identifier, 'rc'
  end

  setting :project do
    setting :path, './'
  end

  setting :output do
    setting :stdout_to, nil
    setting :stderr_to, nil
  end

  setting :version do
    setting :prefix, ''
    setting :validations do
      setting :new_version_must_be_bigger, true
    end
  end

  setting :git do
    setting :pull_before_tag_creation, false
    setting :push_after_tag_creation, false
    setting :fetch_before_tag_creation, false
  end

  setting :changelog do
    setting :format, <<~CHANGELOG
      ## {{new_version}} - #{Time.now.strftime('%d/%m/%Y')}
      {{#version_changes}}
       * {{.}}
      {{/version_changes}}
    CHANGELOG
  end

  setting :hooks, []
  setting :command_options, CommandOptions.new

  ExitError = Class.new(Thor::Error)
  CommandError = Class.new(ExitError)

  def self.root_path
    Pathname.new File.expand_path("#{File.dirname(__FILE__)}/..")
  end

  def self.project_path
    Pathname.new Verto.config.project.path
  end

  def self.container
    @container ||= Dry::Container.new.tap do |container|
      container.register('system_command_executor') { SystemCommandExecutor.new }
      container.register('system_command_executor_without_output') do
        SystemCommandExecutor.new(stdout: nil, stderr: nil)
      end
      container.register('cli_helpers') { CliHelpers }

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

      container.namespace('changelog') do
        register('format') { Verto.config.changelog.format }
      end
    end
  end

  def self.import
    @import ||= Dry::AutoInject(container)
  end

  def self.stdout
    Verto.container.resolve('stdout')
  end

  def self.stderr
    Verto.container.resolve('stderr')
  end

  def self.current_moment
    @current_moment
  end

  def self.current_moment=(moment)
    @current_moment = moment
  end
end

require 'verto/utils/semantic_version'
require 'verto/utils/system_command_executor'
require 'verto/utils/tag_filter'
require 'verto/utils/template'
require 'verto/utils/cli_helpers'
require 'verto/utils/strict_hash'
require 'verto/repositories/tag_repository'
require 'verto/dsl'
require 'verto/dsl/syntax'
require 'verto/dsl/interpreter'
require 'verto/dsl/hook'
require 'verto/dsl/file'
require 'verto/dsl/update_changelog/filtered_by'
require 'verto/dsl/update_changelog/with_merged_pull_requests'
require 'verto/dsl/update_changelog/with_commit_messages'
require 'verto/dsl/update_changelog'
require 'verto/dsl/built_in_hooks'
require 'verto/commands/base_command'
require 'verto/commands/tag_command'
require 'verto/commands/main_command'
