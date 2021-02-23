# frozen_string_literal: true

module TagFilter
  RELEASE_ONLY = /\d+\.\d+\.\d+$/.freeze
  PRE_RELEASE_ONLY = /\d+\.\d+\.\d+-.*\d+/.freeze

  FILTERS = {
    release_only: RELEASE_ONLY,
    pre_release_only: PRE_RELEASE_ONLY,
    all: nil
  }.freeze

  def self.for(tag_key)
    FILTERS[tag_key.to_sym] if tag_key
  end
end
