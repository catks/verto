module Verto
  module DSL
    class Hook
      attr_accessor :moment

      def initialize(interpreter: DSL.interpreter, moment: :before, &block)
        @moment = moment.to_sym
        @interpreter = interpreter
        @block = block
      end

      def call(with_attributes: {})
        @interpreter.evaluate(attributes: with_attributes, &@block)
      end
    end
  end
end
