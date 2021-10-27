# frozen_string_literal: true

module Verto
  module CliHelpers
    class << self
      def confirm(text)
        shell_basic.yes?("#{text} (y/n)")
      end

      def select_options(question, choices)
        tty_prompt.expand(question, choices)
      end

      def edit_text(text)
        tempfile = "/tmp/verto-changelog-edit-#{SecureRandom.hex}"

        TTY::Editor.open(tempfile, text: text)

        edited_text = File.read(tempfile)

        File.delete(tempfile)

        edited_text
      end

      private

      def shell_basic
        @shell_basic ||= Thor::Shell::Basic.new
      end

      def tty_prompt
        @tty_prompt = TTY::Prompt.new
      end
    end
  end
end
