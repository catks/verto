# frozen_string_literal: true

module Verto
  class CommandOptions < Thor::CoreExt::HashWithIndifferentAccess
    alias add merge!

    def except(*keys)
      reject { |key, _v| keys.include?(key) }
    end
  end
end
