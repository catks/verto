# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Verto
  class TagCommand < BaseCommand
    desc 'init', "Create's the first tag"

    def init
      load_config_hooks!

      error_message = 'This repository already has tags'
      raise Verto::ExitError, error_message if tag_repository.any?

      create_git_tag('0.1.0')
    end

    desc 'up', "Create's a new tag"

    option :major, type: :boolean, default: false
    option :minor, type: :boolean, default: false
    option :patch, type: :boolean, default: false
    option :pre_release, type: :string
    option :filter, type: :string
    option :release, type: :boolean, default: false
    option :version_prefix, type: :string, default: nil

    def up
      load_config_hooks!

      call_hooks(%i[before before_tag_up], with_attributes: { command_options: options })

      validate_version_option_presence!

      latest_tag = tag_repository.latest(filter: load_filter)

      validate_latest_tag!(latest_tag)

      latest_version = SemanticVersion.new(latest_tag)

      new_version = up_version(latest_version, options)

      validate_new_version!(new_version, latest_version)

      call_hooks(:before_tag_creation, with_attributes: { new_version: new_version })

      create_git_tag(new_version)

      call_hooks(:after_tag_up, with_attributes: { new_version: new_version })
      call_hooks(:after)
    end

    private

    include Verto.import['tag_repository']

    def up_version(version, options)
      up_options = options.select { |_, value| value == true }.keys.map(&:to_sym) & %i[major minor patch]
      up_option = up_options.min

      new_version = version.up(up_option)

      if options[:pre_release]
        identifier = pre_release_configured? ? options[:pre_release] : version.pre_release.name || default_identifier
        new_version = new_version.with_pre_release(identifier)
        if new_version.pre_release.name == version.pre_release.name && new_version == version
          new_version = new_version.up(:pre_release)
        end
      end

      new_version = new_version.release_version if options[:release]

      new_version
    end

    def create_git_tag(version)
      stderr.puts "Creating Tag #{version_prefix}#{version}..."
      tag_repository.create!("#{version_prefix}#{version}")
      stderr.puts "Tag #{version_prefix}#{version} Created!"
    end

    def pre_release_configured?
      options[:pre_release] != 'pre_release'
    end

    def validate_latest_tag!(latest_tag)
      return if latest_tag

      command_error!(
        <<~TEXT
          Project doesn't have a previous tag version, create a new tag with git.
          eg: `git tag #{version_prefix}0.1.0`
        TEXT
      )
    end

    def validate_new_version!(new_version, latest_version)
      return unless new_version < latest_version && Verto.config.version.validations.new_version_must_be_bigger

      command_error!(
        <<~TEXT
          New version(#{new_version}) can't be equal or lower than latest version(#{latest_version})
          run up --pre-release with --patch, --minor or --major (eg: verto tag up --patch --pre-release=rc),
          add filters (eg: verto tag up --pre-release --filter=pre_release_only)
          or disable tag validation in Vertofile with config.version.validations.new_version_must_be_bigger = false
        TEXT
      )
    end

    def validate_version_option_presence!
      return if options[:major] || options[:minor] || options[:patch] || options[:pre_release] || options[:release]

      command_error!(
        <<~TEXT
          You must specify the version number to be increased, use the some of the options(eg: --major, --minor, --patch, --pre_release=rc)
          or configure a Vertofile to specify a default option for current context, eg:

          context('qa') {
            before_command('tag_up') {
              command_options.add(pre_release: 'rc')
            }
          }
        TEXT
      )
    end

    def load_filter
      TagFilter.for(options[:filter]) || Regexp.new(options[:filter].to_s)
    end

    def version_prefix
      options[:version_prefix] || Verto.config.version.prefix
    end

    def load_config_hooks!
      if Verto.config.git.pull_before_tag_creation
        Verto.config.hooks.prepend Verto::DSL::BuiltInHooks::GitPullCurrentBranch
      end
      Verto.config.hooks << Verto::DSL::BuiltInHooks::GitPushCurrentBranch if Verto.config.git.push_after_tag_creation
    end

    def default_identifier
      Verto.config.pre_release.default_identifier
    end
  end
end
# rubocop:enable Metrics/ClassLength
