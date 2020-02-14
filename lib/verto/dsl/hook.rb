module Verto
  module DSL
    class Hook
      MOMENT = %i[before after]

      module Contexts
        class Any
          def match?(_)
            true
          end
        end

        class Command < Struct.new(:name)
          def match?(command_name)
            name == command_name
          end
        end
      end

      InvalidWhenError = Class.new(StandardError)

      attr_accessor :moment

      def initialize(interpreter: DSL.interpreter, moment: :before, on: Contexts::Any.new, &block)
        raise InvalidWhenError.new("Must be some of these: #{MOMENT}") unless MOMENT.include?(moment)

        @moment = moment
        @interpreter = interpreter
        @context = on
        @block = block
      end

      def call(current_context = nil, with_attributes: {})
        @interpreter.evaluate(attributes: with_attributes, &@block) if @context.match?(current_context)
      end
    end
  end
end
