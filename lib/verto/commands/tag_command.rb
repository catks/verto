module Verto
  class TagCommand < BaseCommand
    desc "up", "Create's a new tag"

    option :major, type: :boolean, default: false
    option :minor, type: :boolean, default: false
    option :patch, type: :boolean, default: false
    option :pre_release, type: :string

    def up
      latest_tag = tag_repository.latest

      validate_latest_tag!(latest_tag)

      latest_version = SemanticVersion.new(latest_tag)

      version_up_options = options.select { |key,value| value == true }.keys.map(&:to_sym) & [:major, :minor, :patch]

      new_version = version_up_options.reduce(latest_version) { |version, up_option| version.up(up_option) }

      if options[:pre_release]
        identifier = pre_release_configured? ? options[:pre_release] : latest_version.pre_release.name
        new_version = new_version.with_pre_release(identifier)
        new_version = new_version.up(:pre_release) if new_version.pre_release.name == latest_version.pre_release.name
      end

      validate_new_version!(new_version, latest_version)
      tag_repository.create!(new_version.to_s)
    end

    private

    include Verto.import['tag_repository']

    def pre_release_configured?
      options[:pre_release] != 'pre_release'
    end

    def validate_latest_tag!(latest_tag)
      command_error!(
        <<~TEXT
          Project doesn't have a previous tag version, create a new tag with git or verto init.
          eg: `git tag 0.0.1` or `verto init`
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
      ) if new_version < latest_version
    end
  end
end
