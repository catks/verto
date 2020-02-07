require "thor"
require "dry-container"
require "dry-configurable"
require "dry-auto_inject"

require "verto/version"

module Verto
  extend Dry::Configurable

  setting :pre_release do
    setting :initial_number, 1
  end

  setting :project do
    setting :path, './'
  end

  def self.root_path
    Pathname.new File.expand_path(File.dirname(__FILE__) + '/..')
  end


  def self.container
    @container ||= Dry::Container.new.tap do |container|
      container.register('system_command_executor') { SystemCommandExecutor.new }
      container.register('tag_repository') { TagRepository.new }

      # TODO: Remove project.path from container
      container.namespace('project') do
        register('path') { Verto.config.project.path }
      end
    end
  end

  def self.import
    @import ||= Dry::AutoInject(container)
  end
end

require "verto/utils/semantic_version.rb"
require "verto/utils/system_command_executor"
require "verto/utils/tag_filter"
require "verto/commands/base_command"
require "verto/commands/tag_command"
require "verto/commands/main_command"
require "verto/repositories/tag_repository"
require "verto/dsl"
