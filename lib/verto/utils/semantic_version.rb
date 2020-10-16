# frozen_string_literal: true

module Verto
  class SemanticVersion < Vseries::SemanticVersion
    DEFAULT_PRE_RELEASE_INITIAL_NUMBER = Verto.config.pre_release.initial_number
  end
end
