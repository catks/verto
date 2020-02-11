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

      def initialize(parser: DSL.parser, moment: :before, on: Any.new, &block)
        raise InvalidWhenError.new("Must be some of these: #{MOMENT}") unless MOMENT.include?(moment)

        @moment = moment
        @parser = parser
        @context = on
        @block = block
      end

      def call(current_context = nil)
        @parser.instance_eval(&@block) if @context.match?(current_context)
      end
    end
  end
end
