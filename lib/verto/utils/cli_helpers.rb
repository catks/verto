# frozen_string_literal: true

module CliHelpers
  class << self
    def confirm(text)
      shell_basic.yes?("#{text} (y/n)")
    end

    private

    def shell_basic
      @shell_basic ||= Thor::Shell::Basic.new
    end
  end
end
