module TagFilter
  REALEASE_ONLY = /\d+\.\d+\.\d+$/
  PRE_REALEASE_ONLY = /\d+\.\d+\.\d+-.*\d+/

  FILTERS = {
    release_only: REALEASE_ONLY,
    pre_release_only: PRE_REALEASE_ONLY,
  }

  def self.for(tag_key)
    FILTERS[tag_key.to_sym] if tag_key
  end
end
