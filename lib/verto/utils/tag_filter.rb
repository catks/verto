module TagFilter
  REALEASE_ONLY = '\d+\.\d+\.\d+$'.freeze
  PRE_REALEASE_ONLY = '\d+\.\d+\.\d+-.*\d+'.freeze

  FILTERS = {
    release_only: REALEASE_ONLY,
    pre_release_only: PRE_REALEASE_ONLY,
    all: nil
  }

  def self.for(tag_key)
    return unless tag_key
    version_prefix = Verto.config.version.prefix

    Regexp.new "#{version_prefix}#{FILTERS[tag_key.to_sym]}"
  end
end
