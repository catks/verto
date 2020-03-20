module Verto
  class CommandOptions < Thor::CoreExt::HashWithIndifferentAccess
    alias_method :add, :merge!

    def except(*keys)
      self.reject { |key, v| keys.include?(key) }
    end
  end
end
