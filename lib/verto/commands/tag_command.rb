module Verto
  class TagCommand < BaseCommand
    desc "up", "Create's a new tag"

    option :major, type: :boolean, default: false
    option :minor, type: :boolean, default: false
    option :patch, type: :boolean, default: false
    option :pre_release, type: :string
    option :filter, type: :string
    option :release, type: :boolean, default: false
    option :version_prefix, type: :string, default: nil

    def up
      load_config_hooks!

      call_hooks(%i[before before_tag_up], with_attributes: { command_options: options} )

      validate_version_option_presence!

      latest_tag = tag_repository.latest(filter: load_filter)

      validate_latest_tag!(latest_tag)

      latest_version = SemanticVersion.new(latest_tag)

      new_version = up_version(latest_version, options)

      validate_new_version!(new_version, latest_version)

      call_hooks(:before_tag_creation, with_attributes: { new_version: new_version } )

      stderr.puts "Creating Tag #{version_prefix}#{new_version}..."
      tag_repository.create!("#{version_prefix}#{new_version}")
      stderr.puts "Tag #{version_prefix}#{new_version} Created!"

      call_hooks(:after_tag_up, with_attributes: { new_version: new_version })
      call_hooks(:after)
    end

    private

    include Verto.import['tag_repository']

    def up_version(version, options)
      up_options = options.select { |key,value| value == true }.keys.map(&:to_sym) & [:major, :minor, :patch]
      up_option = up_options.sort.first

      new_version = version.up(up_option)

      if options[:pre_release]
        identifier = pre_release_configured? ? options[:pre_release] : version.pre_release.name
        new_version = new_version.with_pre_release(identifier)
        new_version = new_version.up(:pre_release) if new_version.pre_release.name == version.pre_release.name && new_version == version
      end

      if options[:release]
        new_version = new_version.release_version
      end

      new_version
    end

    def pre_release_configured?
      options[:pre_release] != 'pre_release'
    end

    def validate_latest_tag!(latest_tag)
      command_error!(
        <<~TEXT
          Project doesn't have a previous tag version, create a new tag with git.
          eg: `git tag #{version_prefix}0.1.0`
        TEXT
      ) unless latest_tag
    end

    def validate_new_version!(new_version, latest_version)
      command_error!(
        <<~TEXT
        New version(#{new_version}) can't be equal or lower than latest version(#{latest_version})
        run up --pre-release with --patch, --minor or --major (eg: verto tag up --pre-release --patch),
        add filters (eg: verto tag up --pre-release --filter=pre_release_only)
        or disable tag validation in Vertofile with config.version.validations.new_version_must_be_bigger = false
        TEXT
      ) if new_version < latest_version && Verto.config.version.validations.new_version_must_be_bigger
    end

    def validate_version_option_presence!
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
      ) unless options[:major] || options[:minor] || options[:patch] || options[:pre_release] || options[:release]
    end

    def load_filter
      TagFilter.for(options[:filter]) || Regexp.new(options[:filter].to_s)
    end

    def version_prefix
      options[:version_prefix] || Verto.config.version.prefix
    end

    def load_config_hooks!
      Verto.config.hooks.prepend Verto::DSL::BuiltInHooks::GitPullCurrentBranch if Verto.config.git.pull_before_tag_creation
      Verto.config.hooks << Verto::DSL::BuiltInHooks::GitPushCurrentBranch if Verto.config.git.push_after_tag_creation
    end
  end
end
