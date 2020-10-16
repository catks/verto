# frozen_string_literal: true

module Verto
  module DSL
    def self.load_file(filepath)
      vertofile_content = IO.read(filepath)

      interpreter.evaluate(vertofile_content)
    end

    def self.interpreter
      @interpreter ||= Interpreter.new
    end

    def self.reset_interpreter!
      @interpreter = nil
    end
  end
end
