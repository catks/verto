# frozen_string_literal: true

module TagFilter
  REALEASE_ONLY = /\d+\.\d+\.\d+$/.freeze
  PRE_REALEASE_ONLY = /\d+\.\d+\.\d+-.*\d+/.freeze

  FILTERS = {
    release_only: REALEASE_ONLY,
    pre_release_only: PRE_REALEASE_ONLY,
    all: nil
  }.freeze

  def self.for(tag_key)
    FILTERS[tag_key.to_sym] if tag_key
  end
end
